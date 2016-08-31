# Office 365 SmartLink #

When a Office365 federated user tries to access resources like http://portal.office.com they would have to type their account (UPN - User Principal Name) before the "home realm discovery" process redirects the user to the single sign-on (identity federation) login page.

In short, Smart Links provide users with an improved login experience when accessing any browser based Office 365 services. The result is a seamless and faster authentication experience. Smart Link is a URL that is a direct access to the IDP (Identity Provider) login page for your Office365 service.

This is an example of a Smart Link (Federation implemented with use of direct SAML2.0 authentication between AzureAD and the FEIDE IDP provider):

https://idp.feide.no/simplesaml/module.php/feide/preselectOrg.php?HomeOrg=**uninett.no**&ReturnTo=https%3A//login.microsoftonline.com/%3Fwhr%3D**uninett.no**

Where in this case **uninett.no** identifies the "home realm".

This URL can be bookmarked in each users web-browser, but it's more common to configure a redirect-service with a more easy URL to remember.

E.g. http://o365.uninett.no

### O365 SmartLink Redirect-Service ###

The flow is:
* User access http://\<myEasyToRememberSmartLink\>
* The Web-Server on \<myEasyToRememberSmartLink\> do a 302 redirect to \<myHardToRememberSmartLink\> 

This can be implemented with use of "Azure App Service":

https://github.com/UNINETT/azure/blob/master/modules/app_service.md

With use of Visual Studio Example-Code at 


## Links ##

- https://blog.kloud.com.au/2012/10/12/office-365-smart-links/
- http://www.nimbus365.co.uk/office-365-sso-with-adfs-and-smart-links/