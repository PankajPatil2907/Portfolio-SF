import { LightningElement, api, track } from 'lwc';

const SECTORS_DATA = [
    {
        id: 'summary',
        index: 0,
        title: 'Professional Summary & COE Delivery',
        tag: 'SECTOR 01 // CENTER OF EXCELLENCE',
        subtitle: 'Enzigma Solutions LLP • Pune, India',
        period: 'Jun 2024 - Present (COE) | Feb 2023 - May 2024 (Platform)',
        palette: ['#00a1e0', '#00f3ff', '#1e293b'],
        scale: 6.2,
        pos: { x: 0, y: 3, z: -22 },
        lookTarget: { x: 0, y: 3, z: -22 },
        highlights: [
            'Certified Salesforce & Agentforce Developer delivering multi-cloud enterprise solutions.',
            'Orchestrated technical solution designs, SOW scoping, and automated CI/CD pipelines raising COE throughput by 25%.',
            'Spearheaded enterprise governance across Sales Cloud, Service Cloud, and Experience Cloud communities.',
            'Delivered 2GP packaging on Salesforce AppExchange with a 100% first-attempt Security Review pass rate.'
        ],
        metrics: [
            { label: 'COE Throughput Boost', value: '+25%' },
            { label: 'AppExchange Pass Rate', value: '100%' },
            { label: 'Certifications Active', value: '6x' },
            { label: 'Integrations Built', value: '500+ Mo' }
        ]
    },
    {
        id: 'skills',
        index: 1,
        title: 'Agentic AI & Enterprise Skill Matrix',
        tag: 'SECTOR 02 // TECHNICAL ARSENAL',
        subtitle: 'Autonomous Orchestration & Core Architecture',
        period: 'Deep Stack Competencies',
        palette: ['#8b00ff', '#00f3ff', '#3b0764'],
        scale: 6.0,
        pos: { x: -36, y: 14, z: -10 },
        lookTarget: { x: -36, y: 14, z: -10 },
        categories: [
            {
                name: 'Agentic AI & Automation',
                skills: ['Agentforce', 'Invocable Apex Tools', 'Prompt Studio', 'Model Context Protocol (MCP)', 'Lightning Flow', 'Flow Orchestrator']
            },
            {
                name: 'Salesforce Core Engineering',
                skills: ['Apex (Triggers, Batchable, Queueable, Schedulable)', 'Lightning Web Components (LWC)', 'SOQL / SOSL', 'Platform Events', 'Custom Metadata', 'Unit Testing & Mock Interfaces']
            },
            {
                name: 'Clouds & Security Architecture',
                skills: ['Sales Cloud', 'Service Cloud', 'Experience Cloud', 'Role Hierarchy', 'Permission Set Groups', 'Sharing Architecture']
            },
            {
                name: 'Integrations & Middleware',
                skills: ['REST / SOAP APIs', 'OAuth 2.0 Webhooks', 'Zapier', 'Zoom API & AI Companion', 'DocuSign API', 'CloudFiles', 'Cin7 ERP', 'Xero Multi-Tenant']
            },
            {
                name: 'DevOps & Tooling',
                skills: ['SFDX', '2GP Managed Packages', 'Scratch Orgs', 'GitLab / GitHub', 'Change Sets', 'Data Loader', 'Angular', 'JIRA']
            }
        ]
    },
    {
        id: 'projects',
        index: 2,
        title: 'Enterprise Mission Logs & Deployments',
        tag: 'SECTOR 03 // ENTERPRISE CLIENTS',
        subtitle: 'VoltEdge, AFPA LMS, AllayPay, Duncan Equine, A-Tech',
        period: 'Production Scale Architectures',
        palette: ['#00f3ff', '#38bdf8', '#0c4a6e'],
        scale: 6.4,
        pos: { x: 38, y: -6, z: -16 },
        lookTarget: { x: 38, y: -6, z: -16 },
        projects: [
            {
                client: 'VoltEdge — Service Cloud & AI Integration',
                bullets: [
                    'Automated Web-to-Case & Email-to-Case with routing rules, handling 500+ monthly cases and slashing latency by 30%.',
                    'Constructed inbound Apex REST Webhook parsing Zoom AI Companion meeting summaries into records, saving 10 hours/week.',
                    'Integrated Zoom Phone via AppExchange for 1-click calling & native logging, reclaiming 5 hrs/week per agent.'
                ]
            },
            {
                client: 'AFPA LMS — Integration & Flow Modernization',
                bullets: [
                    'Built reusable Invocable Apex called from Flows for multi-object logic, accelerating runtime by 30%.',
                    'Connected CloudAssess LMS via Zapier for 1,000+ active enrollments.',
                    'Refactored legacy Process Builders and Workflow Rules into streamlined Flows, cutting governor limit overhead by 25%.'
                ]
            },
            {
                client: 'AllayPay — Document Lifecycle Automation',
                bullets: [
                    'Routed attachments to SharePoint via CloudFiles, reducing storage overhead by 20%.',
                    'Orchestrated multi-document DocuSign batch generation, cutting signature turnaround by 30%.',
                    'Constructed custom triage LWC for inbound emails, accelerating case assignments by 25%.'
                ]
            },
            {
                client: 'Duncan Equine & A-Tech — ERP & Financial Multi-Tenant',
                bullets: [
                    'Bi-directional Cin7 ERP sync processing 500+ monthly orders with 100% data integrity.',
                    'Engineered multi-tenant Xero-to-Salesforce ledger sync with Apex-managed OAuth 2.0 and centralized error logging.'
                ]
            }
        ]
    },
    {
        id: 'appexchange',
        index: 3,
        title: 'PWR Components (AppExchange) & NoKodr',
        tag: 'SECTOR 04 // 2GP PRODUCT MATRIX',
        subtitle: 'Commercial Managed Package Lifecycle',
        period: 'Feb 2023 - May 2024 • Product Engineer',
        palette: ['#ff007f', '#a855f7', '#701a75'],
        scale: 6.0,
        pos: { x: -28, y: -18, z: -28 },
        lookTarget: { x: -28, y: -18, z: -28 },
        details: [
            'Constructed & published "PWR Components" on Salesforce AppExchange (Dynamic Lists, Interactive Timelines, Rating Matrix).',
            'Adopted across 50+ subscriber orgs, slashing front-end UI delivery schedules by 30%.',
            'Spearheaded 2GP Managed Packaging (namespacing, scratch org testing, semantic versioning) passing Security Review on 1st attempt (100% pass rate).',
            'Built responsive Angular front-end components connected to Apex backend controller wrappers.'
        ],
        badges: ['50+ Orgs Adopted', '100% Security Pass', '2GP Second-Gen', 'Zero Governor Flaws']
    },
    {
        id: 'certs',
        index: 4,
        title: 'Official Salesforce Credentials Core',
        tag: 'SECTOR 05 // VERIFIED CREDENTIALS',
        subtitle: '6x Certified Specialist & Consultant',
        period: 'Active & Verified Records',
        palette: ['#10b981', '#06b6d4', '#064e3b'],
        scale: 5.8,
        pos: { x: 26, y: 22, z: -26 },
        lookTarget: { x: 26, y: 22, z: -26 },
        certifications: [
            { id: 'SF-AGNT-2025', name: 'Salesforce Certified Agentforce Specialist', year: '2025' },
            { id: 'SF-PD1-2024', name: 'Salesforce Certified Platform Developer I (PD1)', year: '2024' },
            { id: 'SF-JS1-2024', name: 'Salesforce Certified JavaScript Developer I', year: '2024' },
            { id: 'SF-EXP-2024', name: 'Salesforce Certified Experience Cloud Consultant', year: '2024' },
            { id: 'SF-ADM-2024', name: 'Salesforce Certified Platform Administrator', year: '2024' },
            { id: 'SF-AIA-2024', name: 'Salesforce Certified AI Associate', year: '2024' }
        ]
    },
    {
        id: 'comms',
        index: 5,
        title: 'Academics, Channels & Direct Comms',
        tag: 'SECTOR 06 // DIRECT CONTACT MATRIX',
        subtitle: 'Center for Development of Advanced Computing & SPPU',
        period: 'Available for Strategic Developer Roles',
        palette: ['#f59e0b', '#00f3ff', '#78350f'],
        scale: 6.2,
        pos: { x: 0, y: -26, z: -14 },
        lookTarget: { x: 0, y: -26, z: -14 },
        academics: [
            {
                inst: 'Center for Development of Advanced Computing (C-DAC), Pune',
                degree: 'Post Graduate Diploma in Advanced Computing (PG-DAC)',
                year: '2022'
            },
            {
                inst: 'Savitribai Phule Pune University (SPPU), Pune',
                degree: 'Bachelor of Engineering (B.E.)',
                year: '2018'
            }
        ],
        contact: {
            phone: '+91 8668453504',
            email: 'pankaj.patil2915@gmail.com',
            location: 'Pune, Maharashtra, India',
            linkedin: 'https://linkedin.com/in/pankaj-patil-ab0983181'
        }
    }
];

export default class PortfolioHome extends LightningElement {
    @api componentHeight = '100vh';
    @api enableAudioByDefault = false;

    _showTelemetry = true;

    @api
    get showTelemetry() {
        return this._showTelemetry;
    }
    set showTelemetry(value) {
        this._showTelemetry = value === true || value === 'true';
    }

    @track activeSectorIndex = 0;
    @track isModalOpen = false;
    @track isTerminalOpen = false;
    @track isAudioActive = false;
    @track isWarpDriveActive = false;
    @track terminalInputValue = '';
    @track terminalLogs = [
        { id: 'init-1', cssClass: 'term-res', text: 'Agentforce CLI initialized. Multi-cloud connection active.' },
        { id: 'init-2', cssClass: 'term-res', text: "Type 'help' to inspect available executive commands." }
    ];
    @track toastText = 'System Synced';
    @track isToastVisible = false;
    @track isReticleActive = false;
    @track fpsDisplay = '60 FPS';
    @track pingDisplay = '18ms';

    // 3D Canvas Context and Engine State
    canvas;
    ctx;
    animFrameId;
    isInitialized = false;
    resizeObserver;
    toastTimeout;
    telemetryInterval;

    // Camera Coordinates & Easing State
    cam = { x: 0, y: 8, z: 25 };
    camLook = { x: 0, y: 2, z: -18 };
    camTarget = { x: 0, y: 8, z: 25 };
    lookTarget = { x: 0, y: 2, z: -18 };
    isTweening = false;
    tweenStartTime = 0;
    tweenDuration = 1800;
    tweenStartCam = { x: 0, y: 8, z: 25 };
    tweenStartLook = { x: 0, y: 2, z: -18 };

    // Orbit Drag & Zoom
    isPointerDown = false;
    prevPointer = { x: 0, y: 0 };
    touchStartDist = 0;
    camRotation = { yaw: 0, pitch: 0 };
    hoveredSectorIndex = -1;

    // Universe Particles & Celestial Objects
    stars = [];
    dust = [];
    warpRays = [];
    nebulaClouds = [];
    planetRings = [];
    monolithMeshes = [];

    // Web Audio Synthesizer
    audioCtx = null;
    droneGain = null;
    masterGain = null;

    // Performance frame counting
    frameCount = 0;
    lastFpsTime = 0;

    /* --------------------------------------------------------------------------
       LIFECYCLE HOOKS
       -------------------------------------------------------------------------- */
    renderedCallback() {
        if (!this.isInitialized) {
            this.isInitialized = true;
            this.loadWebFonts();
            this.initCanvasAndUniverse();
            this.startTelemetryLoop();

            if (this.enableAudioByDefault) {
                this.initAudioContext();
            }
        }
    }

    loadWebFonts() {
        try {
            if (typeof document !== 'undefined' && !document.querySelector('link[href*="Orbitron"]')) {
                const link = document.createElement('link');
                link.rel = 'stylesheet';
                link.href = 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Orbitron:wght@500;700;900&family=Rajdhani:wght@500;600;700&display=swap';
                document.head.appendChild(link);
            }
        } catch (e) {
            // Gracefully fall back to system fonts
        }
    }

    disconnectedCallback() {
        if (this.animFrameId) {
            cancelAnimationFrame(this.animFrameId);
        }
        if (this.telemetryInterval) {
            clearInterval(this.telemetryInterval);
        }
        if (this.resizeObserver) {
            this.resizeObserver.disconnect();
        }
        if (this.audioCtx && this.audioCtx.state !== 'closed') {
            this.audioCtx.close();
        }
    }

    /* --------------------------------------------------------------------------
       GETTERS & REACTIVE BINDINGS
       -------------------------------------------------------------------------- */
    get activeSector() {
        return SECTORS_DATA[this.activeSectorIndex] || SECTORS_DATA[0];
    }

    get isSummary() { return this.activeSector.id === 'summary'; }
    get isSkills() { return this.activeSector.id === 'skills'; }
    get isProjects() { return this.activeSector.id === 'projects'; }
    get isAppExchange() { return this.activeSector.id === 'appexchange'; }
    get isCerts() { return this.activeSector.id === 'certs'; }
    get isComms() { return this.activeSector.id === 'comms'; }

    get computedWrapperStyle() {
        const heightVal = this.componentHeight || '100vh';
        return `height: ${heightVal}; min-height: ${heightVal};`;
    }

    get holoModalClass() {
        return `holo-modal cyber-glass corner-cut ${this.isModalOpen ? 'open' : ''}`;
    }

    get terminalDrawerClass() {
        return `terminal-drawer cyber-glass corner-cut ${this.isTerminalOpen ? 'open' : ''}`;
    }

    get reticleClass() {
        return `reticle ${this.isReticleActive ? 'active' : ''}`;
    }

    get toastClass() {
        return `toast-msg cyber-glass font-mono-code ${this.isToastVisible ? 'show' : ''}`;
    }

    get terminalBtnClass() {
        return `cyber-btn corner-cut ${this.isTerminalOpen ? 'active' : ''}`;
    }

    get audioBtnClass() {
        return `cyber-btn corner-cut ${this.isAudioActive ? 'active' : ''}`;
    }

    get warpBtnClass() {
        return `cyber-btn corner-cut ${this.isWarpDriveActive ? 'active' : ''}`;
    }

    get sectorButtons() {
        return SECTORS_DATA.map((s, idx) => ({
            id: s.id,
            index: idx,
            label: `0${idx + 1}. ${s.id.toUpperCase()}`,
            cssClass: `dock-btn cyber-btn ${idx === this.activeSectorIndex ? 'active-dock' : ''}`
        }));
    }

    /* --------------------------------------------------------------------------
       3D PROCEDURAL UNIVERSE & MATH ENGINE
       -------------------------------------------------------------------------- */
    initCanvasAndUniverse() {
        const container = this.template.querySelector('.canvas-container');
        this.canvas = this.template.querySelector('.universe-canvas');
        if (!this.canvas || !container) return;

        this.ctx = this.canvas.getContext ? this.canvas.getContext('2d') : null;
        this.handleResize();

        if (typeof ResizeObserver !== 'undefined') {
            this.resizeObserver = new ResizeObserver(() => this.handleResize());
            this.resizeObserver.observe(container);
        }

        // Generate Celestial Objects
        this.generateStarfield();
        this.generateWarpRays();
        this.generateNebula();
        this.generatePlanetRings();
        this.initMonoliths();

        // Start 60FPS loop
        this.lastFpsTime = performance.now();
        this.animFrameId = requestAnimationFrame((t) => this.animateUniverse(t));
    }

    handleResize() {
        const container = this.template.querySelector('.canvas-container');
        if (!container || !this.canvas) return;
        const rect = container.getBoundingClientRect();
        const dpr = Math.min(window.devicePixelRatio || 1, 2);

        this.canvas.width = rect.width * dpr;
        this.canvas.height = rect.height * dpr;
        this.canvas.style.width = `${rect.width}px`;
        this.canvas.style.height = `${rect.height}px`;

        if (this.ctx) {
            this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }
    }

    generateStarfield() {
        this.stars = [];
        for (let i = 0; i < 450; i++) {
            const r = 180 + Math.random() * 260;
            const theta = Math.random() * Math.PI * 2;
            const phi = Math.acos(2 * Math.random() - 1);
            const x = r * Math.sin(phi) * Math.cos(theta);
            const y = r * Math.sin(phi) * Math.sin(theta);
            const z = r * Math.cos(phi);

            const colors = ['#00f3ff', '#8b00ff', '#ffffff', '#38bdf8'];
            const color = colors[Math.floor(Math.random() * colors.length)];
            const size = 0.8 + Math.random() * 1.6;

            this.stars.push({ x, y, z, color, size, blinkOffset: Math.random() * 10 });
        }

        // Foreground cosmic dust
        this.dust = [];
        for (let i = 0; i < 120; i++) {
            this.dust.push({
                x: (Math.random() - 0.5) * 120,
                y: (Math.random() - 0.5) * 80,
                z: (Math.random() - 0.5) * 100,
                color: 'rgba(0, 243, 255, 0.45)',
                size: 1.2 + Math.random() * 1.5
            });
        }
    }

    generateWarpRays() {
        this.warpRays = [];
        for (let i = 0; i < 280; i++) {
            this.warpRays.push({
                x: (Math.random() - 0.5) * 140,
                y: (Math.random() - 0.5) * 120,
                z: (Math.random() - 0.5) * 200,
                length: 8 + Math.random() * 24,
                speed: 3 + Math.random() * 4
            });
        }
    }

    generateNebula() {
        this.nebulaClouds = [
            { x: -50, y: 15, z: -70, r: 120, color: 'rgba(0, 161, 224, 0.08)' },
            { x: 45, y: -20, z: -80, r: 140, color: 'rgba(139, 0, 255, 0.07)' },
            { x: 0, y: 30, z: -90, r: 110, color: 'rgba(0, 243, 255, 0.06)' }
        ];
    }

    generatePlanetRings() {
        this.planetRings = [];
        for (let i = 0; i < 240; i++) {
            const angle = Math.random() * Math.PI * 2;
            const dist = 28 + Math.random() * 18;
            this.planetRings.push({
                angle,
                dist,
                speed: 0.003 + Math.random() * 0.004,
                yOffset: (Math.random() - 0.5) * 2.2,
                color: Math.random() > 0.4 ? 'rgba(0, 243, 255, 0.7)' : 'rgba(192, 132, 252, 0.6)'
            });
        }
    }

    initMonoliths() {
        this.monolithMeshes = SECTORS_DATA.map((s, idx) => ({
            ...s,
            index: idx,
            gyroAngle: Math.random() * Math.PI,
            pulse: 0
        }));
    }

    /* --------------------------------------------------------------------------
       3D PERSPECTIVE PROJECTION & CAMERA MATRIX
       -------------------------------------------------------------------------- */
    project3D(p, width, height) {
        // Translation relative to camera
        const dx = p.x - this.cam.x;
        const dy = p.y - this.cam.y;
        const dz = p.z - this.cam.z;

        // Camera Yaw & Pitch rotation
        const cosYaw = Math.cos(this.camRotation.yaw);
        const sinYaw = Math.sin(this.camRotation.yaw);
        const cosPitch = Math.cos(this.camRotation.pitch);
        const sinPitch = Math.sin(this.camRotation.pitch);

        // Rotate Y (Yaw)
        const x1 = dx * cosYaw + dz * sinYaw;
        const z1 = -dx * sinYaw + dz * cosYaw;

        // Rotate X (Pitch)
        const y2 = dy * cosPitch - z1 * sinPitch;
        const z2 = dy * sinPitch + z1 * cosPitch;

        // Clip near plane
        if (z2 <= 1.0) return null;

        const fov = 420;
        const scale = fov / z2;
        const screenX = width / 2 + x1 * scale;
        const screenY = height / 2 - y2 * scale;

        return {
            x: screenX,
            y: screenY,
            scale,
            dist: z2
        };
    }

    /* --------------------------------------------------------------------------
       RENDER LOOP (60 FPS)
       -------------------------------------------------------------------------- */
    animateUniverse(time) {
        if (!this.isConnected) return;
        this.animFrameId = requestAnimationFrame((t) => this.animateUniverse(t));
        if (!this.ctx || !this.canvas) return;

        this.frameCount++;
        const width = this.canvas.clientWidth;
        const height = this.canvas.clientHeight;

        // Clear background with deep cosmic black
        this.ctx.fillStyle = '#030712';
        this.ctx.fillRect(0, 0, width, height);

        // Update Camera Easing
        this.updateCameraTween(time);

        // 1. Draw Nebula Clouds
        this.renderNebula(width, height);

        // 2. Draw Distant Starfield
        this.renderStarfield(time, width, height);

        // 3. Draw Cosmic Dust
        this.renderDust(time, width, height);

        // 4. Draw Hyper-Warp Particle Rays
        if (this.isWarpDriveActive) {
            this.renderWarpRays(width, height);
        }

        // 5. Draw Agentforce Core Planet & Orbiting Rings
        this.renderAgentforcePlanet(time, width, height);

        // 6. Draw 3D Sector Monoliths & Gyroscopes
        this.renderMonoliths(time, width, height);
    }

    updateCameraTween(time) {
        if (!this.isTweening) return;
        const elapsed = time - this.tweenStartTime;
        let progress = elapsed / this.tweenDuration;

        if (progress >= 1) {
            progress = 1;
            this.isTweening = false;
        }

        // Smooth cubic in-out ease
        const ease = progress < 0.5
            ? 4 * progress * progress * progress
            : 1 - Math.pow(-2 * progress + 2, 3) / 2;

        this.cam.x = this.tweenStartCam.x + (this.camTarget.x - this.tweenStartCam.x) * ease;
        this.cam.y = this.tweenStartCam.y + (this.camTarget.y - this.tweenStartCam.y) * ease;
        this.cam.z = this.tweenStartCam.z + (this.camTarget.z - this.tweenStartCam.z) * ease;

        this.camLook.x = this.tweenStartLook.x + (this.lookTarget.x - this.tweenStartLook.x) * ease;
        this.camLook.y = this.tweenStartLook.y + (this.lookTarget.y - this.tweenStartLook.y) * ease;
        this.camLook.z = this.tweenStartLook.z + (this.lookTarget.z - this.tweenStartLook.z) * ease;
    }

    renderNebula(width, height) {
        this.nebulaClouds.forEach(neb => {
            const p = this.project3D(neb, width, height);
            if (!p) return;
            const r = neb.r * p.scale * 0.12;
            if (r <= 0) return;

            const grad = this.ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, r);
            grad.addColorStop(0, neb.color);
            grad.addColorStop(1, 'transparent');

            this.ctx.fillStyle = grad;
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
            this.ctx.fill();
        });
    }

    renderStarfield(time, width, height) {
        this.ctx.save();
        this.stars.forEach(s => {
            const p = this.project3D(s, width, height);
            if (!p) return;

            const alpha = 0.55 + 0.45 * Math.sin(time * 0.002 + s.blinkOffset);
            const radius = Math.max(0.6, s.size * (p.scale * 0.08));

            this.ctx.fillStyle = s.color;
            this.ctx.globalAlpha = Math.min(1, alpha);
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, radius, 0, Math.PI * 2);
            this.ctx.fill();
        });
        this.ctx.restore();
    }

    renderDust(time, width, height) {
        this.ctx.save();
        this.ctx.fillStyle = '#00f3ff';
        this.dust.forEach((d, idx) => {
            const floatY = d.y + Math.sin(time * 0.001 + idx) * 1.5;
            const p = this.project3D({ x: d.x, y: floatY, z: d.z }, width, height);
            if (!p) return;

            this.ctx.globalAlpha = 0.35;
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y, Math.max(0.7, d.size * p.scale * 0.04), 0, Math.PI * 2);
            this.ctx.fill();
        });
        this.ctx.restore();
    }

    renderWarpRays(width, height) {
        this.ctx.save();
        this.ctx.strokeStyle = '#00f3ff';
        this.ctx.lineWidth = 1.6;

        this.warpRays.forEach(ray => {
            ray.z += ray.speed;
            if (ray.z > 20) {
                ray.z = -140;
            }

            const p1 = this.project3D(ray, width, height);
            const p2 = this.project3D({ x: ray.x, y: ray.y, z: ray.z - ray.length }, width, height);
            if (!p1 || !p2) return;

            this.ctx.globalAlpha = 0.75;
            this.ctx.beginPath();
            this.ctx.moveTo(p1.x, p1.y);
            this.ctx.lineTo(p2.x, p2.y);
            this.ctx.stroke();
        });
        this.ctx.restore();
    }

    renderAgentforcePlanet(time, width, height) {
        const planetCenter = { x: -60, y: -22, z: -100 };
        const p = this.project3D(planetCenter, width, height);
        if (!p) return;

        const radius = 24 * p.scale * 0.14;
        if (radius <= 2) return;

        this.ctx.save();

        // Atmospheric Fresnel Halo Outer Glow
        const haloGrad = this.ctx.createRadialGradient(p.x, p.y, radius * 0.8, p.x, p.y, radius * 1.45);
        haloGrad.addColorStop(0, 'rgba(0, 243, 255, 0.45)');
        haloGrad.addColorStop(0.5, 'rgba(139, 0, 255, 0.2)');
        haloGrad.addColorStop(1, 'transparent');
        this.ctx.fillStyle = haloGrad;
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, radius * 1.45, 0, Math.PI * 2);
        this.ctx.fill();

        // Planet Body
        const bodyGrad = this.ctx.createRadialGradient(p.x - radius * 0.35, p.y - radius * 0.35, radius * 0.1, p.x, p.y, radius);
        bodyGrad.addColorStop(0, '#00a1e0');
        bodyGrad.addColorStop(0.5, '#051b3d');
        bodyGrad.addColorStop(1, '#020713');
        this.ctx.fillStyle = bodyGrad;
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, radius, 0, Math.PI * 2);
        this.ctx.fill();

        // Orbiting Ring Particles
        this.planetRings.forEach(ring => {
            ring.angle += ring.speed;
            const rx = planetCenter.x + Math.cos(ring.angle) * ring.dist;
            const rz = planetCenter.z + Math.sin(ring.angle) * ring.dist;
            const ry = planetCenter.y + ring.yOffset + Math.sin(ring.angle) * 4;

            const ringProj = this.project3D({ x: rx, y: ry, z: rz }, width, height);
            if (ringProj) {
                this.ctx.fillStyle = ring.color;
                this.ctx.globalAlpha = 0.65;
                this.ctx.beginPath();
                this.ctx.arc(ringProj.x, ringProj.y, Math.max(0.6, 1.2 * ringProj.scale * 0.1), 0, Math.PI * 2);
                this.ctx.fill();
            }
        });

        this.ctx.restore();
    }

    renderMonoliths(time, width, height) {
        let hoverFound = -1;

        this.monolithMeshes.forEach(mono => {
            mono.gyroAngle += 0.015;
            const floatY = mono.pos.y + Math.sin(time * 0.0016 + mono.index) * 0.4;
            const p = this.project3D({ x: mono.pos.x, y: floatY, z: mono.pos.z }, width, height);
            if (!p) return;

            const cardW = 90 * (p.scale * 0.048);
            const cardH = 125 * (p.scale * 0.048);
            mono.screenBounds = { x: p.x - cardW / 2, y: p.y - cardH / 2, w: cardW, h: cardH };

            const isHovered = this.prevPointer.x >= mono.screenBounds.x &&
                              this.prevPointer.x <= mono.screenBounds.x + cardW &&
                              this.prevPointer.y >= mono.screenBounds.y &&
                              this.prevPointer.y <= mono.screenBounds.y + cardH;

            if (isHovered) {
                hoverFound = mono.index;
            }

            const isSelected = mono.index === this.activeSectorIndex;

            this.ctx.save();

            // 1. Monolith Card Background
            this.ctx.fillStyle = isHovered ? 'rgba(8, 23, 54, 0.92)' : 'rgba(4, 11, 25, 0.85)';
            this.ctx.strokeStyle = isSelected ? '#00f3ff' : (isHovered ? mono.palette[1] : 'rgba(0, 243, 255, 0.35)');
            this.ctx.lineWidth = isSelected ? 2.5 : 1.2;

            this.ctx.beginPath();
            if (this.ctx.roundRect) {
                this.ctx.roundRect(mono.screenBounds.x, mono.screenBounds.y, cardW, cardH, 6);
            } else {
                this.ctx.rect(mono.screenBounds.x, mono.screenBounds.y, cardW, cardH);
            }
            this.ctx.fill();
            this.ctx.stroke();

            // 2. Gyroscopic Rotating Rings
            this.ctx.strokeStyle = isHovered ? '#00f3ff' : 'rgba(0, 243, 255, 0.25)';
            this.ctx.lineWidth = 1;
            this.ctx.beginPath();
            const ringRadius = cardW * 0.75;
            this.ctx.ellipse(p.x, p.y, ringRadius, ringRadius * 0.35, mono.gyroAngle, 0, Math.PI * 2);
            this.ctx.stroke();

            // 3. Monolith Header Bar & Emissive Badge
            this.ctx.fillStyle = mono.palette[0];
            this.ctx.fillRect(mono.screenBounds.x + 6, mono.screenBounds.y + 6, cardW - 12, 3);

            // 4. Sci-Fi Radar Glyphs & Typography
            this.ctx.textAlign = 'center';
            this.ctx.fillStyle = '#67e8f9';
            this.ctx.font = `bold ${Math.max(8, Math.floor(10 * p.scale * 0.04))}px 'Orbitron', monospace`;
            this.ctx.fillText(`SECTOR 0${mono.index + 1}`, p.x, mono.screenBounds.y + 20);

            // Radar Circle
            const radarR = Math.max(10, 16 * p.scale * 0.04);
            this.ctx.strokeStyle = isHovered ? '#00f3ff' : 'rgba(0, 243, 255, 0.4)';
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y - 4, radarR, 0, Math.PI * 2);
            this.ctx.stroke();

            // Central Node
            this.ctx.fillStyle = isHovered ? '#ff007f' : '#00f3ff';
            this.ctx.beginPath();
            this.ctx.arc(p.x, p.y - 4, 3, 0, Math.PI * 2);
            this.ctx.fill();

            // Bottom Title
            this.ctx.fillStyle = '#f8fafc';
            this.ctx.font = `600 ${Math.max(7, Math.floor(9 * p.scale * 0.04))}px 'Rajdhani', sans-serif`;
            const shortTitle = mono.id.toUpperCase();
            this.ctx.fillText(shortTitle, p.x, mono.screenBounds.y + cardH - 14);

            this.ctx.restore();
        });

        if (hoverFound !== this.hoveredSectorIndex) {
            this.hoveredSectorIndex = hoverFound;
            this.isReticleActive = hoverFound !== -1;
            if (hoverFound !== -1) {
                this.playBlip(1040, 0.05);
            }
        }
    }

    /* --------------------------------------------------------------------------
       WARP NAVIGATION & CAMERA CONTROLS
       -------------------------------------------------------------------------- */
    warpToSector(index, openModal = true) {
        if (index < 0 || index >= SECTORS_DATA.length) return;
        this.activeSectorIndex = index;
        const sector = SECTORS_DATA[index];

        this.playWarpChord();
        this.showToast(`Warping to Sector 0${index + 1}: ${sector.title}`);

        const offsetZ = sector.scale * 2.2;
        this.camTarget = {
            x: sector.pos.x,
            y: sector.pos.y,
            z: sector.pos.z + offsetZ
        };
        this.lookTarget = { ...sector.lookTarget };

        this.tweenStartCam = { ...this.cam };
        this.tweenStartLook = { ...this.camLook };
        this.tweenStartTime = performance.now();
        this.isTweening = true;

        if (openModal) {
            setTimeout(() => {
                this.isModalOpen = true;
            }, 500);
        }
    }

    handleResetCamera() {
        this.playBlip(520, 0.15);
        this.showToast('Coordinate Space Recalibrated');
        this.isModalOpen = false;

        this.camTarget = { x: 0, y: 8, z: 25 };
        this.lookTarget = { x: 0, y: 2, z: -18 };
        this.camRotation = { yaw: 0, pitch: 0 };

        this.tweenStartCam = { ...this.cam };
        this.tweenStartLook = { ...this.camLook };
        this.tweenStartTime = performance.now();
        this.isTweening = true;
    }

    /* --------------------------------------------------------------------------
       INTERACTION HANDLERS (POINTER, DOCK, MODAL)
       -------------------------------------------------------------------------- */
    handlePointerDown(event) {
        this.isPointerDown = true;
        this.prevPointer = { x: event.clientX, y: event.clientY };
    }

    handlePointerMove(event) {
        const rect = this.canvas ? this.canvas.getBoundingClientRect() : { left: 0, top: 0 };
        this.prevPointer = {
            x: event.clientX - rect.left,
            y: event.clientY - rect.top
        };

        if (this.isPointerDown) {
            const dx = event.movementX || 0;
            const dy = event.movementY || 0;

            this.camRotation.yaw -= dx * 0.003;
            this.camRotation.pitch = Math.max(-0.6, Math.min(0.6, this.camRotation.pitch + dy * 0.003));
        }
    }

    handlePointerUp() {
        this.isPointerDown = false;
    }

    handleWheel(event) {
        event.preventDefault();
        const delta = Math.sign(event.deltaY) * 3;
        this.camTarget.z = Math.max(-20, Math.min(65, this.cam.z + delta));
        this.cam.z = this.camTarget.z;
    }

    handleTouchStart(event) {
        if (event.touches.length === 1) {
            this.isPointerDown = true;
            this.prevPointer = { x: event.touches[0].clientX, y: event.touches[0].clientY };
        } else if (event.touches.length === 2) {
            this.touchStartDist = Math.hypot(
                event.touches[0].pageX - event.touches[1].pageX,
                event.touches[0].pageY - event.touches[1].pageY
            );
        }
    }

    handleTouchMove(event) {
        if (event.touches.length === 1 && this.isPointerDown) {
            const dx = event.touches[0].clientX - this.prevPointer.x;
            const dy = event.touches[0].clientY - this.prevPointer.y;
            this.camRotation.yaw -= dx * 0.004;
            this.camRotation.pitch = Math.max(-0.6, Math.min(0.6, this.camRotation.pitch + dy * 0.004));
            this.prevPointer = { x: event.touches[0].clientX, y: event.touches[0].clientY };
        } else if (event.touches.length === 2) {
            const dist = Math.hypot(
                event.touches[0].pageX - event.touches[1].pageX,
                event.touches[0].pageY - event.touches[1].pageY
            );
            const delta = (this.touchStartDist - dist) * 0.1;
            this.cam.z = Math.max(-20, Math.min(65, this.cam.z + delta));
            this.touchStartDist = dist;
        }
    }

    handleTouchEnd() {
        this.isPointerDown = false;
    }

    handleCanvasClick() {
        if (this.hoveredSectorIndex !== -1) {
            this.warpToSector(this.hoveredSectorIndex, true);
        }
    }

    handleDockClick(event) {
        const sectorIndex = parseInt(event.currentTarget.dataset.sector, 10);
        this.warpToSector(sectorIndex, true);
    }

    handleDirectResumeClick() {
        this.warpToSector(0, true);
    }

    handleCloseModal() {
        this.playBlip(440, 0.1);
        this.isModalOpen = false;
    }

    handleNextSector() {
        const next = (this.activeSectorIndex + 1) % SECTORS_DATA.length;
        this.warpToSector(next, true);
    }

    handlePulseResonance() {
        this.playWarpChord();
        this.showToast('Transmitting Harmonic Pulse');
        const mono = this.monolithMeshes[this.activeSectorIndex];
        if (mono) {
            mono.gyroAngle += Math.PI;
        }
    }

    toggleTerminal() {
        this.isTerminalOpen = !this.isTerminalOpen;
        this.playBlip(750, 0.1);
    }

    toggleWarpMode() {
        this.isWarpDriveActive = !this.isWarpDriveActive;
        if (this.isWarpDriveActive) {
            this.playWarpChord();
            this.showToast('Engaging Hyper-Warp Particles');
        } else {
            this.playBlip(480, 0.1);
            this.showToast('Sub-Light Velocity Restored');
        }
    }

    /* --------------------------------------------------------------------------
       PROCEDURAL WEB AUDIO SYNTHESIZER
       -------------------------------------------------------------------------- */
    initAudioContext() {
        if (this.audioCtx) return;
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (!AudioCtx) return;

        this.audioCtx = new AudioCtx();
        this.masterGain = this.audioCtx.createGain();
        this.masterGain.gain.setValueAtTime(0.25, this.audioCtx.currentTime);
        this.masterGain.connect(this.audioCtx.destination);

        // Low ambient cosmic drone
        const osc1 = this.audioCtx.createOscillator();
        const osc2 = this.audioCtx.createOscillator();
        const filter = this.audioCtx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(130, this.audioCtx.currentTime);

        this.droneGain = this.audioCtx.createGain();
        this.droneGain.gain.setValueAtTime(0.18, this.audioCtx.currentTime);

        osc1.type = 'sawtooth';
        osc1.frequency.setValueAtTime(55, this.audioCtx.currentTime);
        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(55.3, this.audioCtx.currentTime);

        osc1.connect(filter);
        osc2.connect(filter);
        filter.connect(this.droneGain);
        this.droneGain.connect(this.masterGain);

        osc1.start();
        osc2.start();
        this.isAudioActive = true;
    }

    toggleAudio() {
        if (!this.audioCtx) {
            this.initAudioContext();
            this.isAudioActive = true;
            this.showToast('Cosmic Synthesizer Active');
            this.playBlip(880, 0.2);
            return;
        }

        if (this.audioCtx.state === 'suspended') {
            this.audioCtx.resume();
        }

        this.isAudioActive = !this.isAudioActive;
        if (this.masterGain) {
            this.masterGain.gain.setValueAtTime(this.isAudioActive ? 0.25 : 0.0001, this.audioCtx.currentTime);
        }

        this.showToast(this.isAudioActive ? 'Cosmic Synthesizer Active' : 'Audio Conduits Muted');
        if (this.isAudioActive) {
            this.playBlip(880, 0.2);
        }
    }

    playBlip(freq = 780, duration = 0.12) {
        if (!this.isAudioActive || !this.audioCtx) return;
        try {
            const osc = this.audioCtx.createOscillator();
            const gain = this.audioCtx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, this.audioCtx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(freq * 1.6, this.audioCtx.currentTime + duration);

            gain.gain.setValueAtTime(0.14, this.audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, this.audioCtx.currentTime + duration);

            osc.connect(gain);
            gain.connect(this.masterGain);
            osc.start();
            osc.stop(this.audioCtx.currentTime + duration);
        } catch (e) {
            // Audio policy protection
        }
    }

    playWarpChord() {
        if (!this.isAudioActive || !this.audioCtx) return;
        try {
            [523.25, 659.25, 783.99, 1046.5].forEach((freq, idx) => {
                const osc = this.audioCtx.createOscillator();
                const gain = this.audioCtx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(freq, this.audioCtx.currentTime);

                const startTime = this.audioCtx.currentTime + idx * 0.04;
                gain.gain.setValueAtTime(0.08, startTime);
                gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.9);

                osc.connect(gain);
                gain.connect(this.masterGain);
                osc.start(startTime);
                osc.stop(startTime + 0.95);
            });
        } catch (e) {
            // Audio policy protection
        }
    }

    /* --------------------------------------------------------------------------
       CLI TERMINAL ENGINE
       -------------------------------------------------------------------------- */
    handleTerminalInput(event) {
        this.terminalInputValue = event.target.value;
    }

    handleTerminalSubmit(event) {
        event.preventDefault();
        const raw = (this.terminalInputValue || '').trim().toLowerCase();
        this.terminalInputValue = '';
        if (!raw) return;

        this.playBlip(920, 0.08);
        this.addTerminalLog('term-cmd', `$ ${raw}`);

        const parts = raw.split(' ');
        const cmd = parts[0];

        switch (cmd) {
            case 'help':
                this.addTerminalLog('term-res', 'Available Executive Commands:');
                this.addTerminalLog('term-res', '• warp <1-6> : Jump camera trajectory to sector');
                this.addTerminalLog('term-res', '• skills : Inspect Agentic AI & Core SFDC skills');
                this.addTerminalLog('term-res', '• certs : Retrieve 6x certified credentials');
                this.addTerminalLog('term-res', '• exp : View enterprise mission logs');
                this.addTerminalLog('term-res', '• pwr : Details on PWR AppExchange 2GP Package');
                this.addTerminalLog('term-res', '• contact : View direct communication telemetry');
                this.addTerminalLog('term-res', '• clear : Clear terminal display buffer');
                break;
            case 'warp': {
                const target = parseInt(parts[1], 10);
                if (target >= 1 && target <= 6) {
                    this.warpToSector(target - 1, true);
                    this.addTerminalLog('term-success', `Executing jump trajectory to Sector 0${target}...`);
                } else {
                    this.addTerminalLog('term-error', 'Invalid sector. Specify 1 through 6 (e.g. warp 2).');
                }
                break;
            }
            case 'skills':
                this.warpToSector(1, true);
                this.addTerminalLog('term-success', 'Loading Agentic AI, Invocable Apex & LWC Matrices...');
                break;
            case 'certs':
                this.warpToSector(4, true);
                this.addTerminalLog('term-success', 'Retrieving 6x verified Salesforce certifications...');
                break;
            case 'exp':
                this.warpToSector(2, true);
                this.addTerminalLog('term-success', 'Opening VoltEdge, AFPA, AllayPay & ERP mission logs...');
                break;
            case 'pwr':
                this.warpToSector(3, true);
                this.addTerminalLog('term-success', 'Loading PWR Components AppExchange 2GP package spec...');
                break;
            case 'contact':
                this.warpToSector(5, true);
                this.addTerminalLog('term-res', 'Phone: +91 8668453504');
                this.addTerminalLog('term-res', 'Email: pankaj.patil2915@gmail.com');
                this.addTerminalLog('term-res', 'Location: Pune, Maharashtra, India');
                break;
            case 'clear':
                this.terminalLogs = [];
                break;
            default:
                this.addTerminalLog('term-error', `Command '${cmd}' not recognized. Type 'help' for command manual.`);
        }
    }

    addTerminalLog(cssClass, text) {
        this.terminalLogs = [
            ...this.terminalLogs,
            {
                id: `log-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
                cssClass,
                text
            }
        ];
        setTimeout(() => {
            const logsEl = this.template.querySelector('.terminal-logs');
            if (logsEl) {
                logsEl.scrollTop = logsEl.scrollHeight;
            }
        }, 50);
    }

    /* --------------------------------------------------------------------------
       TELEMETRY & TOAST
       -------------------------------------------------------------------------- */
    startTelemetryLoop() {
        this.telemetryInterval = setInterval(() => {
            const now = performance.now();
            const delta = (now - this.lastFpsTime) / 1000;
            const currentFps = Math.round(this.frameCount / delta);
            this.frameCount = 0;
            this.lastFpsTime = now;

            this.fpsDisplay = `${Math.min(currentFps || 60, 60)} FPS`;
            this.pingDisplay = `${Math.floor(14 + Math.random() * 8)}ms`;
        }, 1000);
    }

    showToast(message) {
        this.toastText = message;
        this.isToastVisible = true;
        clearTimeout(this.toastTimeout);
        this.toastTimeout = setTimeout(() => {
            this.isToastVisible = false;
        }, 2600);
    }
}
