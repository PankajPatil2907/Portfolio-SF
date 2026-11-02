import { LightningElement, api, track, wire } from 'lwc';
import processVoiceInteraction from '@salesforce/apex/AgentforceVoiceController.processVoiceInteraction';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';

export default class AgentforceVoiceBot extends LightningElement {
    @api recordId; // Automatically injected if placed on a Record Page

    @track currentRecordId = null;
    @track messages = [];
    @track statusMessage = 'Idle. Click microphone to speak.';
    @track isListening = false;
    @track isProcessing = false;
    @track isSpeaking = false;
    @track ttsEnabled = true;

    recognition;
    synth = window.speechSynthesis;
    navInterval;

    @wire(CurrentPageReference)
    handlePageNavigation(pageRef) {
        this.detectActiveRecordId(pageRef);
    }

    connectedCallback() {
        this.initSpeechRecognition();
        this.detectActiveRecordId();

        // Utility Bar polling: automatically update context badge when user switches tabs/records
        this.navInterval = setInterval(() => {
            this.detectActiveRecordId();
        }, 1200);
    }

    disconnectedCallback() {
        if (this.navInterval) {
            clearInterval(this.navInterval);
        }
        if (this.silenceTimer) {
            clearTimeout(this.silenceTimer);
        }
        if (this.recognition) {
            try {
                this.recognition.abort();
            } catch (e) {
                // ignore on cleanup
            }
        }
        if (this.synth && this.synth.speaking) {
            this.synth.cancel();
        }
    }

    detectActiveRecordId(pageRef) {
        // Priority 1: Injected @api recordId (if component is placed on a Record Page)
        if (this.recordId && typeof this.recordId === 'string' && this.recordId.length >= 15) {
            if (this.currentRecordId !== this.recordId) {
                this.currentRecordId = this.recordId;
            }
            return;
        }

        // Priority 2: PageReference attributes (from navigation)
        const refId = pageRef?.attributes?.recordId || pageRef?.state?.recordId;
        if (refId && typeof refId === 'string' && refId.length >= 15) {
            if (this.currentRecordId !== refId) {
                this.currentRecordId = refId;
            }
            return;
        }

        // Priority 3: Browser URL in Utility Bar / Single Page App
        try {
            const url = window.location.href;
            const match = url.match(/\/lightning\/r\/(?:[a-zA-Z0-9_]+\/)?([a-zA-Z0-9]{15,18})\//);
            if (match && match[1]) {
                if (this.currentRecordId !== match[1]) {
                    this.currentRecordId = match[1];
                }
                return;
            }
        } catch (e) {
            // ignore
        }

        // If on Home page or other non-record tab
        if (!this.recordId && this.currentRecordId !== null) {
            this.currentRecordId = null;
        }
    }

    get effectiveRecordId() {
        return this.currentRecordId;
    }

    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    get recordContextLabel() {
        const recId = this.effectiveRecordId;
        return recId ? `Record: ${recId.substring(0, 15)}` : '';
    }

    get micButtonTitle() {
        if (this.isListening) return 'Stop listening';
        if (this.isProcessing) return 'Agentforce processing...';
        return 'Click to speak';
    }

    get micCtaText() {
        if (this.isListening) return 'Listening... Speak now';
        if (this.isProcessing) return 'Agentforce thinking...';
        return 'Tap to Speak';
    }

    get micButtonClass() {
        let base = 'mic-button';
        if (this.isListening) {
            base += ' mic-active';
        }
        return base;
    }

    get micWrapperClass() {
        return this.isListening ? 'mic-wrapper listening' : 'mic-wrapper';
    }

    get micIconName() {
        return this.isListening ? 'utility:unmuted' : 'utility:voice_call';
    }

    get micIconVariant() {
        return this.isListening ? 'inverse' : '';
    }

    get volumeIcon() {
        return this.ttsEnabled ? 'utility:volume_high' : 'utility:volume_off';
    }

    get statusBadgeClass() {
        let base = 'slds-badge ';
        if (this.isListening) {
            base += 'slds-badge_inverse status-listening';
        } else if (this.isProcessing) {
            base += 'slds-theme_warning';
        } else if (this.isSpeaking) {
            base += 'slds-theme_success';
        } else {
            base += 'slds-badge_lightest';
        }
        return base;
    }

    silenceTimer = null;
    liveTranscript = '';

    initSpeechRecognition() {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRecognition) {
            this.statusMessage = 'Web Speech API is not supported in this browser.';
            return;
        }

        try {
            this.recognition = new SpeechRecognition();
            this.recognition.lang = 'en-US';
            this.recognition.continuous = true;
            this.recognition.interimResults = true;

            this.recognition.onstart = () => {
                this.isListening = true;
                this.liveTranscript = '';
                this.statusMessage = 'Listening... Speak your instruction.';
            };

            this.recognition.onresult = (event) => {
                let accumulated = '';
                for (let i = 0; i < event.results.length; i++) {
                    accumulated += event.results[i][0].transcript + ' ';
                }
                accumulated = accumulated.trim();
                if (accumulated.length > 0) {
                    this.liveTranscript = accumulated;
                    this.statusMessage = 'Listening: "' + accumulated + '"';

                    // Reset silence debounce timer on each spoken fragment
                    if (this.silenceTimer) {
                        clearTimeout(this.silenceTimer);
                    }
                    // Wait for 1.8s of silence before auto-finalizing to prevent cutting off mid-sentence
                    this.silenceTimer = setTimeout(() => {
                        this.finalizeSpeechTurn();
                    }, 1800);
                }
            };

            this.recognition.onerror = (event) => {
                if (this.silenceTimer) {
                    clearTimeout(this.silenceTimer);
                }
                this.isListening = false;
                if (event.error === 'no-speech') {
                    if (this.liveTranscript && this.liveTranscript.trim().length > 0) {
                        this.finalizeSpeechTurn();
                    } else {
                        this.statusMessage = 'No speech detected. Try again.';
                    }
                } else if (event.error === 'not-allowed') {
                    this.statusMessage = 'Microphone permission denied.';
                } else {
                    this.statusMessage = 'Speech error: ' + event.error;
                }
            };

            this.recognition.onend = () => {
                this.isListening = false;
                if (this.liveTranscript && this.liveTranscript.trim().length > 0 && !this.isProcessing) {
                    this.finalizeSpeechTurn();
                } else if (!this.isProcessing && !this.isSpeaking) {
                    this.statusMessage = 'Idle. Click microphone to speak.';
                }
            };
        } catch (e) {
            this.statusMessage = 'Could not initialize speech recognition.';
        }
    }

    finalizeSpeechTurn() {
        if (this.silenceTimer) {
            clearTimeout(this.silenceTimer);
            this.silenceTimer = null;
        }

        const text = this.liveTranscript ? this.liveTranscript.trim() : '';
        this.liveTranscript = '';

        if (this.recognition) {
            try {
                this.recognition.stop();
            } catch (e) {
                // ignore
            }
        }

        if (text && text.length > 0) {
            this.addMessage('You', text, 'user');
            this.executeTurn(text);
        }
    }

    handleMicToggle() {
        if (!this.recognition) {
            this.initSpeechRecognition();
            if (!this.recognition) return;
        }

        if (this.isListening) {
            // Clicking mic while listening immediately finalizes speech
            this.finalizeSpeechTurn();
        } else {
            if (this.synth && this.synth.speaking) {
                this.synth.cancel();
                this.isSpeaking = false;
            }
            this.liveTranscript = '';
            try {
                this.recognition.start();
            } catch (err) {
                try {
                    this.recognition.abort();
                    this.recognition.start();
                } catch (ignore) {
                    this.statusMessage = 'Microphone busy. Please try again.';
                }
            }
        }
    }

    async executeTurn(userText) {
        this.isProcessing = true;
        this.statusMessage = 'Agentforce is thinking...';
        this.detectActiveRecordId(); // Ensure most up-to-date context

        const targetRecordId = this.effectiveRecordId;

        try {
            const payload = JSON.stringify({
                prompt: userText,
                recordId: targetRecordId || null
            });

            const result = await processVoiceInteraction({ payloadJson: payload });
            this.isProcessing = false;

            const responseText = result.responseText || 'Request processed.';
            this.addMessage('Agentforce', responseText, 'agent');

            // Automatically notify Lightning Data Service to refresh the record page UI in the background
            if (targetRecordId) {
                try {
                    await notifyRecordUpdateAvailable([{ recordId: targetRecordId }]);
                } catch (notifyErr) {
                    // ignore if LDS refresh fails
                }
            }

            if (this.ttsEnabled) {
                this.speak(responseText);
            } else {
                this.statusMessage = 'Idle. Click microphone to speak.';
            }
        } catch (error) {
            this.isProcessing = false;
            this.statusMessage = 'Error processing request.';
            const errorMsg = error.body?.message || error.message || 'Unknown execution error.';
            this.addMessage('System', errorMsg, 'error');
        }
    }

    speak(text) {
        if (!this.synth || !this.ttsEnabled) return;

        this.synth.cancel();
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = 'en-US';
        utterance.rate = 1.0;

        utterance.onstart = () => {
            this.isSpeaking = true;
            this.statusMessage = 'Speaking response...';
        };

        utterance.onend = () => {
            this.isSpeaking = false;
            this.statusMessage = 'Idle. Click microphone to speak.';
        };

        utterance.onerror = () => {
            this.isSpeaking = false;
            this.statusMessage = 'Idle. Click microphone to speak.';
        };

        this.synth.speak(utterance);
    }

    stopSpeech() {
        if (this.synth && this.synth.speaking) {
            this.synth.cancel();
            this.isSpeaking = false;
            this.statusMessage = 'Speech stopped.';
        }
    }

    handleAudioToggle() {
        this.ttsEnabled = !this.ttsEnabled;
        if (!this.ttsEnabled && this.synth && this.synth.speaking) {
            this.synth.cancel();
            this.isSpeaking = false;
        }
    }

    handleClearHistory() {
        this.messages = [];
        this.statusMessage = 'History cleared. Ready.';
    }

    addMessage(sender, text, type) {
        let containerClass = 'chat-message-row ';
        let avatarIcon = 'utility:user';

        if (type === 'user') {
            containerClass += 'chat-row-user';
            avatarIcon = 'utility:user';
        } else if (type === 'agent') {
            containerClass += 'chat-row-agent';
            avatarIcon = 'utility:einstein';
        } else {
            containerClass += 'chat-row-error';
            avatarIcon = 'utility:error';
        }

        const now = new Date();
        const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        this.messages = [
            ...this.messages,
            {
                id: Date.now() + Math.random(),
                sender,
                text,
                timestamp: timeStr,
                containerClass,
                avatarIcon
            }
        ];

        // Auto-scroll chat to latest message
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const viewport = this.template.querySelector('.chat-viewport');
            if (viewport) {
                viewport.scrollTop = viewport.scrollHeight;
            }
        }, 100);
    }
}