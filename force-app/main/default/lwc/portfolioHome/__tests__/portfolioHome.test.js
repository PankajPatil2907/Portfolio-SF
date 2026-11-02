import { createElement } from '@lwc/engine-dom';
import PortfolioHome from 'c/portfolioHome';

describe('c-portfolio-home', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the cyber portfolio header and title', () => {
        const element = createElement('c-portfolio-home', {
            is: PortfolioHome
        });

        document.body.appendChild(element);

        const title = element.shadowRoot.querySelector('.main-title');
        expect(title).not.toBeNull();
        expect(title.textContent).toBe('PANKAJ PATIL');
    });

    it('opens photo lightbox popup when avatar badge is clicked', () => {
        const element = createElement('c-portfolio-home', {
            is: PortfolioHome
        });

        document.body.appendChild(element);

        const avatarBadge = element.shadowRoot.querySelector('.avatar-badge');
        expect(avatarBadge).not.toBeNull();

        avatarBadge.click();

        return Promise.resolve().then(() => {
            const picModal = element.shadowRoot.querySelector('.pic-modal-backdrop');
            expect(picModal).not.toBeNull();
            expect(picModal.classList.contains('open')).toBe(true);
        });
    });
});
