import { LightningElement, wire, track } from 'lwc';
import getMyLeaves from '@salesforce/apex/LeaveRequestController.getMyLeaves';
import { refreshApex } from '@salesforce/apex';

export default class LeaveTracker extends LightningElement {
  @track leaves = [];
  columns = [
    { label: 'Leave ID', fieldName: 'Name' },
    { label: 'From Date', fieldName: 'From_Date__c', type: 'date' },
    { label: 'To Date', fieldName: 'To_Date__c', type: 'date' },
    { label: 'Reason', fieldName: 'Reason__c' },
    { label: 'Status', fieldName: 'Status__c' }
  ];

  @wire(getMyLeaves)
  wiredLeaves({ error, data }) {
    if (data) {
      this.leaves = data;
    } else if (error) {
      // handle error
    }
  }

  handleSuccess() {
    // Refresh data after successful record creation
    return refreshApex(this.leaves);
  }
}
