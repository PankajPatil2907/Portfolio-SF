import { LightningElement, track } from 'lwc';
import syncInvoices from '@salesforce/apex/XeroInvoiceActionHandler.syncFromLWC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class XeroInvoiceSync extends LightningElement {

    @track selectedOption = 'default';
    @track lastSyncTime;

    options = [
        { label: 'Sync Last 10 Minutes', value: 'default' },
        { label: 'Sync with Custom Date/Time', value: 'custom' }
    ];

    get isDateDisabled() {
        return this.selectedOption === 'default';
    }

    connectedCallback() {
        // Pre-fill default (Now - 10 mins)
        let now = new Date();
        now.setMinutes(now.getMinutes() - 10);
        this.lastSyncTime = now.toISOString();
    }

    handleOptionChange(event) {
        this.selectedOption = event.detail.value;

        if (this.selectedOption === 'default') {
            // Reset to Now - 10 mins
            let now = new Date();
            now.setMinutes(now.getMinutes() - 10);
            this.lastSyncTime = now.toISOString();
        } else {
            // Optional: clear value when switching to custom
            this.lastSyncTime = null;
        }
    }

    handleDateChange(event) {
        this.lastSyncTime = event.target.value;
    }

    handleSync() {

        let inputDate = null;

        if (this.selectedOption === 'custom') {
            inputDate = this.lastSyncTime;
        }

        syncInvoices({ lastSyncTime: inputDate })
            .then(() => {
                this.showToast('Success', 'Sync started successfully', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}