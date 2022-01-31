/* Author: Ryan Reddish - Capgemini
 * Date: 1/23/2022
 * Purpose: Use this class to store all HttpCallouts for SFS Outbound Intgrations.
 */

public class Outbound_Integration_Callout {
    /*	All integrations will use this method. They will pass a identifier 'interfaceDetail'. 
     * 	Query uses interfaceDetail to identify the endpoint that needs to be called.
     */ 
    
    @future(Callout = true)
    public static void HttpMethod(String xmlString, String interfaceDetail){
        //Http Method to send xml and recieve success or failure code.
        Integration_Endpoint__mdt endpoint = [SELECT Endpoint_URL, UserName, Password
                                                  FROM Integration_Endpoint__mdt
                                                  WHERE Label =: interfaceDetail];
        
        //Encoding credentials for Authorization Header
       	Blob headervalue = Blob.valueOf(endpoint.UserName + ':' + endpoint.Password);
        String authorizationHeader = 'Basic' + EncodingUtil.base64Encode(headerValue);
        
        //Http Request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('Content-Type', 'text/xml');
        request.setTimeout(120000);
        request.setBody(xmlString);
        System.debug('Payload: ' + xmlString);
        
        //Get Http Response
        HttpResponse response = http.send(request);
        System.debug('STATUS: ' + response.getStatusCode());
    }
}