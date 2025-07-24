import { LightningElement, track } from 'lwc';
import getAllParties from '@salesforce/apex/DigitalVotingBoothController.getAllParties';
import submitVote from '@salesforce/apex/DigitalVotingBoothController.submitVote';

export default class DigitalVotingBooth extends LightningElement {
    @track parties = [];
    @track selectedPartyId;
    @track isBlank = false;
    @track blankNote = '';
    @track successMessage = '';

    connectedCallback() {
        this.loadParties();
    }

    async loadParties() {
        try {
            const result = await getAllParties();
            this.parties = result;
        } catch (error) {
            console.error('Error loading parties:', error);
        }
    }

    get blankCardClass() {
        const base = 'party-box slds-box slds-m-around_small slds-text-align_center slds-theme_warning';
        return this.isBlank ? `${base} selected` : base;
    }

    get filteredParties() {
        return this.parties
            .filter(p => p.PartyCode__c)
            .map(p => {
                const isSelected = this.selectedPartyId === p.Id && !this.isBlank;
                return {
                    ...p,
                    computedClass: `party-box slds-box slds-m-around_small slds-text-align_center${isSelected ? ' selected' : ''}`
                };
            });
    }
    

    get hasParties() {
        return this.filteredParties.length > 0;
    }

    handleOuterClick(event) {
        const clickedElement = event.target;
        if (
            clickedElement.closest('.party-box') || 
            clickedElement.closest('lightning-textarea')
        ) {
            return;
        }
        this.selectedPartyId = null;
        this.isBlank = false;
        this.blankNote = '';
    }

    handlePartySelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedPartyId = selectedId;
        this.isBlank = false;
        this.blankNote = '';
    }

    handleBlankSelect() {
        this.selectedPartyId = null;
        this.isBlank = true;
    }

    handleBlankNoteChange(event) {
        this.blankNote = event.target.value;
    }

    async submitVote() {
        try {
            await submitVote({ partyId: this.selectedPartyId, blankNote: this.isBlank ? this.blankNote : null });
            this.successMessage = 'Your vote has been submitted successfully!';
            this.selectedPartyId = null;
            this.blankNote = '';
            this.isBlank = false;
        } catch (error) {
            console.error('Error submitting vote:', error);
        }
    }

    getCardClass(partyId) {
        const base = 'party-box slds-box slds-m-around_small slds-text-align_center';
        const selected = this.selectedPartyId === partyId && !this.isBlank;
        const blankSelected = this.isBlank && partyId === null;
        return selected || blankSelected ? `${base} selected` : base;
    }
}
