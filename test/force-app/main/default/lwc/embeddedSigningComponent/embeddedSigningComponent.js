import { LightningElement, api } from 'lwc';
import userId from '@salesforce/user/Id';
import sendEnvelope from '@salesforce/apex/EmbeddedSigningController.sendEnvelope';
import getEmbeddedSigningUrl from '@salesforce/apex/EmbeddedSigningController.getEmbeddedSigningUrl';
import updateAccountSigningDate from '@salesforce/apex/EmbeddedSigningController.updateAccountSigningDate';
import updateAccountCollaborationSigningDate from '@salesforce/apex/EmbeddedSigningController.updateAccountCollaborationSigningDate';
import getAccountSigningDate from '@salesforce/apex/EmbeddedSigningController.getAccountSigningDate';


const ndaCookieName = "ndaButtonClick";
const agreementCookieName = "agreementButtonClick";
const hideNDAButtonCookieName = "hideNDAButton";
const hideAgreementButtonCookieName = "hideAgreementButton";

export default class EmbeddedSigningComponent extends LightningElement {

    ndaTemplate = 'afbe3b5d-0fae-4a42-bf3f-dae950d970ed';
    ndaDescription = 'Mutual NDA';

    agreementTemplate = 'fda8240a-c913-4d98-8130-3e7e91b1cb06';
    agreementDescription = 'Collaboration Agreement';

    @api recordId;
    @api templateId;
    @api buttonLabel;
    @api buttonTitle;
    @api buttonStyle;
    @api buttonVariant;
    @api templateDescription;
    @api signedMessage;
    @api signedMessageStyle;
    
    showButton = false;
    showSignedMessage = false;
    // showLoadingAnimation = true;
    // recentlyClicked = false;

    handleClick(evt) {
        
        
        console.log('Preparing to send DocuSign Envelope.');

        // Clear URL Params
        // Clean Up URL
        // if(this.recentlyClicked === false) {
        window.history.pushState({}, document.title, window.location.origin + "/s/");           //remove url parameters and add url to history because DocuSign will just keep appending the same parameter and it is then impossible to determine what exactly happened
        // }

        if(this.buttonLabel.includes("NDA")) {
            // If NDA Clicked, add URL parameter to URL before initializing the embedded signing session
            window.history.pushState({}, document.title, window.location.origin + "/s/?docName=" + 'NDA');
        } else if (this.buttonLabel.includes("Agreement")) {
            // If Collaboration Clicked, add URL parameter to URL before initializing the embedded signing session
            window.history.pushState({}, document.title, window.location.origin + "/s/?docName=" + 'Collaboration');
        }

        // this.recentlyClicked = true;

        // Initialize and send DocuSign Envelope from DocuSign EnvelopeTemplate
        sendEnvelope({template: evt.currentTarget.dataset.templateId, description: evt.currentTarget.dataset.templateDescription, recordId: userId})
            .then((envelopeId) => (
                // Generate The Embedded Signing URL
                getEmbeddedSigningUrl({
                    envId: envelopeId,
                    url: window.location.href
                })
            ))
            .then((signingUrl) => {
                console.log('DocuSign Envelope Sent. Initializing Embedded Signing Session.');
                window.location.href = signingUrl;
            })
            .catch((error) => {
                console.log('Error:');
                console.log(error);
                // REset clicked param
                // this.recentlyClicked = false; 
            });
    }

    renderedCallback() {
        let urlParams = {};
        
        let parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
            urlParams[key] = value;
        });
        
        console.log('Embedded Signing Button Initialized - ' + this.buttonLabel);

        // if() {
        if(this.buttonLabel.includes("NDA")) {
            console.log('NDA Button Initialized');

            getAccountSigningDate({documentName: "NDA", recordId: userId})
                .then((resp) => {
                    console.log('Is NDA Signed - ' + resp);
                    if(resp === 'false') {                                                                                                  // IF DOCUMENT NOT SIGNED - - - - - 
                       // Show Button
                       this.showButton = true;
                        if(urlParams["event"] === "signing_complete" && urlParams['docName'] === 'NDA') {                                   // Check the URL Params to determine if NDA was initialized and the signing session was complete (AKA the document was signed)
                            console.log('NDA Signing Recently Completed');
                            this.showButton = false;                                                                                        // Hide the Button
                            updateAccountSigningDate({documentName: "NDA", recordId: userId})                                               // Updated Account.NDA_Date__c
                                .then((resp) => {                                                                                           // Process the response
                                    console.log('NDA Signing Date Updated');
                                    location.reload();                                                                                      // reload the page to catch the onboarding step update that changes the community audience
                                    window.history.pushState({}, document.title, window.location.origin + "/s/");                           // Clean Up URL
                                });
                        }
                    } else {                                                                                                                // IF DOCUMENT SIGNED - - - - - 
                        console.log('NDA Is Already Signed');
                        this.showButton = false;                                                                                            // Hide button
                        this.showSignedMessage = true;                                                                                      // Show @api signedMessage
                    }
                })
        // } else if() {
        } else if(this.buttonLabel.includes("Agreement")) {
            console.log('Collab Button Initialized');

            getAccountSigningDate({documentName: "Collaboration", recordId: userId})
                .then((resp) => {
                    console.log('Is Collab Signed - ' + resp);
                    if(resp === 'false') {
                        // Show Button
                        this.showButton = true;
                        if(urlParams["event"] === "signing_complete" && urlParams['docName'] === 'Collaboration') {
                            console.log('Collab Signing Recently Completed');
                            this.showButton = false;                                                                                       //
                            updateAccountCollaborationSigningDate({documentName: "Collaboration", recordId: userId})                       // Added to store date NDA was signed
                                .then((resp) => {
                                    console.log('Collab Signing Date Updated');
                                    location.reload();                                                                                     // reload the page to catch the onboarding step update that changes the community audience
                                    window.history.pushState({}, document.title, window.location.origin + "/s/");                          // Clean Up URL
                                });
                        }
                    } else {
                        console.log('Collab is already signed');
                        this.showButton = false;
                        this.showSignedMessage = true;
                    }
                })

        }
    }
}