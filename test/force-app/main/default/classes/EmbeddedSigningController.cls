/**
 * @description       : 
 * @author            : robert@venturetechgroup.com
 * @group             : VentureTech Group
 * @last modified on  : 2021-08-30
 * @last modified by  : robert@venturetechgroup.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   2021-06-16   robert@venturetechgroup.com   Initial Version
**/
public without sharing class EmbeddedSigningController {

    public static String standardErrorMessage = 'There was an issue initializing your DocuSign Document. Please try again later. If you continue to receive this error, please reach out to the system administrator';

    /**
    * @description 
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String template - DocuSign Envelope Template Id
    * @param String description - Template name/description
    * @param Id recordId - Id of the Salesforce user that initalized the session
    * @return String 
    **/
    @AuraEnabled
    public static String sendEnvelope(String template, String description, Id recordId){
        try {
        
            Id mySourceId = recordId; // The ID of the initiating Salesforce object
            User usr;

            if(Test.isRunningTest()) {
                usr = [
                    SELECT Id, Name, Email, Contact.Name, Contact.Title, Contact.AccountId, Contact.Account.Name, Contact.Phone, Contact.Email, Contact.Account.NDA_Date__c,
                        Contact.Account.Partnership_Agreement_Signed__c, Contact.MailingStreet, Contact.MailingCity, Contact.MailingState, Contact.MailingPostalCode
                    FROM User
                    WHERE Name='TestDSDCommunity Contact'
                ];
            } else {
                usr = [
                    SELECT Id, Name, Email, Contact.Name, Contact.Title, Contact.AccountId, Contact.Account.Name, Contact.Phone, Contact.Email, Contact.Account.NDA_Date__c,
                        Contact.Account.Partnership_Agreement_Signed__c, Contact.MailingStreet, Contact.MailingCity, Contact.MailingState, Contact.MailingPostalCode
                    FROM User
                    WHERE Id = :recordId
                ];
            }

            

            // Get Developer Application
            Co_Developer_Application__c developerApplication = [SELECT Id, Legal_Company_Name__c, Company_Street__c, Company_City__c, Company_State__c, Company_Postal_Code__c, Title__c, Phone__c, Email__c, Primary_Partner_Contact_Name__c, Primary_Contact_Last_Name__c, Portal_Account__r.NDA_Date__c
                                                                FROM Co_Developer_Application__c 
                                                                WHERE Portal_Account__c = :usr.Contact.AccountId 
                                                                ORDER BY CreatedDate DESC
                                                                LIMIT 1];

            // PRODUCTION SIGNER
            User dsdUser = [
                SELECT Id, Name, Email
                FROM User
                WHERE Name = 'Eric Pollock'
                LIMIT 1
            ];

            //Signed documents should be saved in SF as an attachment
            //get attachments work done over forwarding

            // Build Formatted NDA Signed Date
            String formattedDate = developerApplication.Portal_Account__r?.NDA_Date__c?.month() + '-' + developerApplication.Portal_Account__r?.NDA_Date__c?.day() + '-' + developerApplication.Portal_Account__r?.NDA_Date__c?.year();

            dfsle.Recipient otherPartyRecipient = dfsle.Recipient.newEmbeddedSigner(usr.Name, usr.Email, usr.Id)
                .withTabs(
                    new List<dfsle.Tab> { // Associate the tabs with this recipient
                        getDateSignedTab(),
                        getNDASignedtDateTab(formattedDate),
                        getOtherPartySignatureTab(),
                        getOtherPartyPhoneTab(developerApplication.Phone__c, 'Other Party Phone'),
                        getOtherPartyEmailTab(developerApplication.Email__c, 'Other Party Email'),
                        getOtherPartyEntityTab(developerApplication.Legal_Company_Name__c, 'Other Party Entity'),
                        getOtherPartyNameTab(developerApplication.Primary_Partner_Contact_Name__c + ' ' + developerApplication.Primary_Contact_Last_Name__c, 'Other Party Name'),
                        getOtherPartyTitleTab(developerApplication.Title__c, 'Other Party Title'),
                        getOtherPartyAddressLineOneTab(developerApplication.Company_Street__c, 'Other Party Address Line One'),
                        getOtherPartyAddressLineTwoTab(developerApplication.Company_City__c + ', ' + developerApplication.Company_State__c + ' ' + developerApplication.Company_Postal_Code__c, 'Other Party Address Line Two')
                    }
                )
                .withRoutingOrder(1);
            
            
            // TESTING RECIPIENT
            // dfsle.Recipient dsdRecipient = dfsle.Recipient.fromSource(
            //         'VentureTech',
            //         'sfdc+dsd@venturetechgroup.com',
            //         null,
            //         'null',
            //         new dfsle.Entity('0055G000006iaxgQAA')
            //     )
            //     .withTabs(
            //         new List<dfsle.Tab> { // Associate the tabs with this recipient
            //             getDateSignedTab(),
            //             getDSDSignatureTab(),
            //             getDSDPhoneTab(),
            //             getDSDEmailTab(),
            //             getNDASignedtDateTab(formattedDate)
            //         }
            //     )
            //     .withRoutingOrder(2);

            // PRODUCTION RECIPIENT
            dfsle.Recipient dsdRecipient = dfsle.Recipient.fromSource(
                    dsdUser.Name,
                    dsdUser.Email,
                    null,
                    'null',
                    new dfsle.Entity(dsdUser.Id)
                )
                .withTabs(
                    new List<dfsle.Tab> { // Associate the tabs with this recipient
                        getDateSignedTab(),
                        getDSDSignatureTab(),
                        getDSDPhoneTab(),
                        getDSDEmailTab(),
                        getNDASignedtDateTab(formattedDate)
                    }
                )
                .withRoutingOrder(2);

            // Create an empty envelope and add a Salesforce Document and embedded signer  recipient
            // The embedded signer will be the current user with sequence and routing order 1 and role "Signer 1" by default
            dfsle.Envelope dsEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
                    new dfsle.Entity(mySourceId)) // The initiating Salesforce entity--current SF user (salesperson)
                .withDocuments(new List<dfsle.Document> {
                    dfsle.Document.fromTemplate(dfsle.UUID.parse(template), description)
                })
                .withRecipients(new List<dfsle.Recipient> {
                    otherPartyRecipient, //other party recipient first, Eric Pollock second
                    dsdRecipient
                }
            );
            
            
            if(Test.isRunningTest()) {
                // Savepoint sp = Database.setSavepoint();
                // Database.rollback(sp);
                dsEnvelope = dfsle.EnvelopeService.sendEnvelope(dsEnvelope, true);
            } else {
                // Send the envelope.
                dsEnvelope = dfsle.EnvelopeService.sendEnvelope(
                    dsEnvelope, // The envelope to send
                    true // Send now?
                );
            }
            // Return string value of DocuSign envelope ID

            System.debug('^^^DocuSign ID -> ' + String.valueOf(dsEnvelope.docuSignId));

            dfsle__Envelope__c envelope = [
                SELECT Id, Name, dfsle__DocuSignId__c
                FROM dfsle__Envelope__c
                WHERE dfsle__DocuSignId__c = :String.valueOf(dsEnvelope.docuSignId)
                AND dfsle__SourceId__c = :mySourceId
            ];

            envelope.Associated_Customers_Partner__c = usr.Contact.AccountId;
            update envelope;

            return String.valueOf(dsEnvelope.docuSignId);
        } catch (Exception e) {
            System.debug(e.getMessage());
            // Throw AuraException
            throw new AuraHandledException(standardErrorMessage);    
           
        }
    }


    /**
    * @description Update the date a DocuSign document was signed by the DSD Connect community user. 
                   This information is stored on the User's Account record
    * @author robert@venturetechgroup.com | 2021-08-23 
    * @param String documentName - Can be "NDA" or "Collaboration"
    * @param Id recordId 
    * @return string 
    **/
    @AuraEnabled
    public static string updateAccountSigningDate(String documentName, Id recordId){
        try {
            // Get Signed In User
            User usr = [
                SELECT Id, Name, Email, Contact.AccountId
                FROM User
                WHERE Id = :recordId
            ];

            // Initialize Account Object For User's Account
            Account communityUserAccount = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c, Portal_Status__c 
                                            FROM Account
                                            WHERE Id = :usr.Contact.AccountId];
            // new Account(Id=usr.Contact.AccountId);

            // Do Signing Date Update
            if(documentName == 'NDA') {
                communityUserAccount.NDA_Date__c = Date.today();
                if(communityUserAccount?.Partnership_Agreement_Signed__c != null & communityUserAccount?.Partnership_Agreement_Signed__c <= Date.today()) {
                    communityUserAccount.Portal_Status__c = 'Onboarding - Application';
                } else {
                    communityUserAccount.Partnership_Agreement_Signed__c = null;
                }
            } 

            // Update Signing Date Of Document For User's Account
            Database.SaveResult updateResult = Database.update(communityUserAccount);

            if(!updateResult.isSuccess()) {
                // Throw exception if signing date could not be saved
                throw new AuraHandledException('There was a problem updating the status of your onboarding application. Please try again.');
            }

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Update the date a DocuSign document was signed by the DSD Connect community user. 
                   This information is stored on the User's Account record
    * @author robert@venturetechgroup.com | 2021-08-23 
    * @param String documentName - Can be "NDA" or "Collaboration"
    * @param Id recordId 
    * @return string 
    **/
    @AuraEnabled
    public static string updateAccountCollaborationSigningDate(String documentName, Id recordId){
        try {
            // Get Signed In User
            User usr = [
                SELECT Id, Name, Email, Contact.AccountId
                FROM User
                WHERE Id = :recordId
            ];

            // Initialize Account Object For User's Account
            Account communityUserAccount = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c, Portal_Status__c 
                                            FROM Account
                                            WHERE Id = :usr.Contact.AccountId];
            // new Account(Id=usr.Contact.AccountId);

            // Do Signing Date Update
            if (documentName == 'Collaboration') {
                communityUserAccount.Partnership_Agreement_Signed__c = Date.today();
                if(communityUserAccount?.NDA_Date__c != null & communityUserAccount?.NDA_Date__c <= Date.today()) {
                    communityUserAccount.Portal_Status__c = 'Onboarding - Application';
                } else {
                    communityUserAccount.NDA_Date__c = null;
                }
            }

            // Update Signing Date Of Document For User's Account
            Database.SaveResult updateResult = Database.update(communityUserAccount);

            if(!updateResult.isSuccess()) {
                // Throw exception if signing date could not be saved
                throw new AuraHandledException('There was a problem updating the status of your onboarding application. Please try again.');
            }

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description - Get the date a specific document was signed
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String documentName 
    * @param Id recordId 
    * @return string - if true document is signed, if false document is not signed
    **/
    @AuraEnabled
    public static string getAccountSigningDate(String documentName, Id recordId){
        try {
            // Get Signed In User
            User usr = [
                SELECT Id, Name, Email, Contact.AccountId
                FROM User
                WHERE Id = :recordId
            ];

            // Get Account
            Id acctId = usr.Contact.AccountId;
            Account communityUserAccount = [SELECT Id, NDA_Date__c, Partnership_Agreement_Signed__c FROM Account WHERE Id = :acctId];

            // Get Signed Date
            String response = '';
            if(documentName == 'NDA') {
                if(communityUserAccount?.NDA_Date__c != null) {
                    response = 'true';
                } else {
                    response = 'false';
                }
            } else if (documentName == 'Collaboration') {
                if(communityUserAccount?.Partnership_Agreement_Signed__c != null) {
                    response = 'true';
                } else {
                    response = 'false';
                }
            }

            // Return Date Signed
            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description - Get the URL to redirect the user and initialize a new
                     DocuSign Embedded Sigining Session
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String envId - DocuSign Envelope Template Id
    * @param String url - DocuSign Embedded Signing Url
    * @return String - Full URL to initialize Embedded Signing
    **/
    @AuraEnabled
    public static String getEmbeddedSigningUrl(String envId, String url){
        try {
        
            Url mySigningUrl = dfsle.SigningService.getEmbeddedSigningUrl(
            dfsle.UUID.parse(envId), // envId value as a UUID
            new URL(url) // url value as a URL
            );
            // Return string value of url to controller
            return mySigningUrl.toExternalForm();
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            // Throw AuraException
            throw new AuraHandledException(standardErrorMessage);    
        
        }
    }


    /**
     * 
     * CUSTOM DOCUMENT TABS
     * 
     */
    private static dfsle.Tab getDateSignedTab() {
        return new dfsle.DateSignedTab()
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/datesigned/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    private static dfsle.Tab getDSDSignatureTab() {
        return new dfsle.SignHereTab()
            .withRequired(true) // Signing mandatory
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/dsdsignature/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the date the NDA was signed through DocuSign in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String ndaSignedDate 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getNDASignedtDateTab(String ndaSignedDate) {
        return new dfsle.TextTab()
            .withValue(ndaSignedDate)
            .withRequired(true) // Signing mandatory
            .withReadOnly(true)
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/ndasigneddate/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    private static dfsle.Tab getDSDPhoneTab() {
        return new dfsle.TextTab()
            .withValue('518-949-0165')
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel('DSD Phone')
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/dsdphone/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    private static dfsle.Tab getDSDEmailTab() {
        return new dfsle.TextTab()
            .withValue('connect@dsdrenewables.com')
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel('DSD Email')
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/dsdemail/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    private static dfsle.Tab getOtherPartySignatureTab() {
        return new dfsle.SignHereTab()
            .withRequired(true) // Signing mandatory
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartysignature/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the phone number from the developer application in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerPhone 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyPhoneTab(String developerPhone, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerPhone)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) // 'Other Party Phone'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyphone/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the email address from the developer application in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerEmail 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyEmailTab(String developerEmail, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerEmail)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) //'Other Party Email'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyemail/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Create the Legal Entity Name DS Tab. It is required and should be populated
                     by the Legal Entity Name field on the developer application
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String legalEntityName - Initial Value for document tab
    * @param String dataLabel - data label for the document tab input
    * @return dfsle.Tab - the DocuSign Tab for the embedded signing document
    **/
    private static dfsle.Tab getOtherPartyEntityTab(String legalEntityName, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(legalEntityName)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) // 'Other Party Entity'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyentityname/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the full name of the signer from the developer application in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerSignerName 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyNameTab(String developerSignerName, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerSignerName)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) //'Other Party Name'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyfullname/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the signer title from the developer application in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerSignerTitle 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyTitleTab(String developerSignerTitle, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerSignerTitle)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) //'Other Party Title'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartytitle/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the street address from the developer application on a single line in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerAddressLine 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyAddressLineOneTab(String developerAddressLine, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerAddressLine)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) //'Other Party Address Line One'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyaddressone/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }

    /**
    * @description - Display the city, state, and postal code from the developer application on a single line in a DocuSign Tab
    * @author robert@venturetechgroup.com | 2021-08-28 
    * @param String developerAddressLine 
    * @param String dataLabel 
    * @return dfsle.Tab 
    **/
    private static dfsle.Tab getOtherPartyAddressLineTwoTab(String developerAddressLine, String dataLabel) {
        return new dfsle.TextTab()
            .withValue(developerAddressLine)
            .withReadOnly(false)
            .withRequired(true) // Signing mandatory
            .withDataLabel(dataLabel) //'Other Party Address Line Two'
            .withAnchor(
                new dfsle.Tab.Anchor(
                    '/otherpartyaddresstwo/', // Anchor string
                    false, // Do not allow white space in anchor string
                    false, // Anchor string is not case sensitive
                    '', // Horizontal alignment in relation to the anchor text
                    true, // Ignore if the anchor text is not present in the document
                    true, // Must match the value of the anchor string in its entirety
                    'pixels', // Unit of the x and y offset properties
                    0, // X offset
                    0 // Y offset
                )
            );
    }
}