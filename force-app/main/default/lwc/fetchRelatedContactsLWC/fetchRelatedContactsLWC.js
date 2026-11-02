import { LightningElement, track, api } from 'lwc';
import fetchContacts from '@salesforce/apex/FetchAccAssociatedContactsController.fetchRelatedContacts';


export default class FetchRelatedContactsLWC extends LightningElement {



    @track data = [];
    @track columns = [
        { label: "Id", fieldName: "Id", type: "text" },
        { label: "Name", fieldName: "Name", type: "text" },
        {
            label: "Email", fieldName: "Email", type: "email",
        },
        {
            label: "Phone", fieldName: "Phone", type: "phone",
        }

    ];

    async handleSelectAccount(event) {
        let accId = event.detail?.recordId;
        let result = await fetchContacts({ accId: accId });
        console.log(JSON.stringify(result));
        this.data = [...result];
        console.log(accId);

    }

    getSelectedName(event) {

    }




}