import { LightningElement } from 'lwc';
import getAllParties from '@salesforce/apex/DigitalVotingBoothController.getAllParties';
import submitVote from '@salesforce/apex/DigitalVotingBoothController.submitVote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DigitalVotingBooth extends LightningElement {
    parties = [];
    selectedPartyId;
    isBlank = false;
    blankNote = '';

    //trigger loadParties on page load
    connectedCallback() {
        this.loadParties();
    }

    // Call Apex to retrieve all valid parties from the server
    async loadParties() {
        try {
            const result = await getAllParties();
            this.parties = result;
        } catch (error) {
            console.error('Error loading parties:', error);
        }
    }

    // Returns the dynamic CSS class for the blank vote card
    get blankCardClass() {
        const base = 'party-box slds-box slds-m-around_small slds-text-align_center slds-theme_warning';
        return this.isBlank ? `${base} selected` : base;
    }

    // Filters and transforms party list to attach UI class based on selection
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

    //Getter to check if there are any valid parties, if not show message
    get hasParties() {
        return this.filteredParties.length > 0;
    }

    //Disable submit button until party is selected
    get isSubmitDisabled() {
        return !this.selectedPartyId && !this.isBlank;
    }

    //clear party selection when pressing outside party object
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

    // Handles user selecting a party by card click
    handlePartySelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedPartyId = selectedId;
        this.isBlank = false;
        this.blankNote = '';
    }

    // Handles user selecting the blank vote option
    handleBlankSelect() {
        this.selectedPartyId = null;
        this.isBlank = true;
    }

    // Handles user typing text for blank vote justification
    handleBlankNoteChange(event) {
        this.blankNote = event.target.value;
    }

    // Submits the vote (party vote or blank note) via Apex
    async submitVote() {
        try {
            await submitVote({ partyId: this.selectedPartyId, blankNote: this.isBlank ? this.blankNote : null });

            // Show success toast
            this.dispatchEvent(new ShowToastEvent({
                title: 'Vote Submitted',
                message: 'Your vote has been submitted successfully!',
                variant: 'success',
                mode: 'dismissable'
            }));

            // Reset form
            this.selectedPartyId = null;
            this.blankNote = '';
            this.isBlank = false;
        } catch (error) {
            console.error('Error submitting vote:', error);

            // Show error toast
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'There was a problem submitting your vote.',
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }
}
