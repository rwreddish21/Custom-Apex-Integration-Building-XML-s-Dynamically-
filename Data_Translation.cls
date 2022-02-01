/* Author: Ryan Reddish - Capgemini
* Date: 12/1/21
* Description: For use with outbound integrations that require data translations in Salesforce instead of middleware.
*
*/
public class Outbound_Integration_Data_Transformation{
public static void Run(List <Id> newId){
    //Main Method
    String xmlString = '';
    Map<Double, String> finalXmlMap = new Map<Double, String>();      
    TranslateData(newId, finalXMLMap, xmlString);
    
}

//Refactored method
public static void TranslateData (List <Id> newId, Map<Double, String> finalXMLMap, String xmlString){
    //Method to Process Salesforce Record, and convert to target payload syntax.
    //Query custom metadata and all objects needed for payload.
    XML_Outbound_Mapping__mdt[] xmlMap = [SELECT Salesforce_Field__c,Salesforce_Object__c, Child_Start__c, Node_Order__c, XML_Full_Name__c, XML_Object__c, Hardcoded_Flag__c 
                                                        FROM XML_Outbound_Mapping__mdt Order By Node_Order__c asc];    
    ServiceContract sa = [SELECT Id From ServiceAGREMENT WHERE Id =: newId];
    
    //Map Queries, then populate using getPopulatedFieldAsMap()
    
    Map<String, Object> servAgMap = new Map<String, Object>();
    servAgMap = sa.getPopulatedFieldsAsMap();
    
    
    //Loop through each map.keyset(), populate one map with all fieldname values from individual maps
    
    Map<String, Object> FieldValues = new Map<String, Object>();
    
    for(String field: servAgMap.keyset()){
        try{
            FieldValues.put(field.toLowerCase(), sa.get(field));
        }catch(sObjectException e){
            
        }
    
    //Replace fieldNames (value) in FieldValues with the XML Line and Salesforce Data.
    List<Double> newNodeList = new List<Double>();
    for(XML_Outbound_Mapping__mdt xmlStructure : xmlMap){
        newNodeList.add(xmlStructure.Node_Order__c);
        //check for hardcoded flag. If false, replace data.
        if(xmlStructure.Hardcoded_Flag__c == false){
            String sfField = xmlStructure.Salesforce_Field__c;
            if(FieldValues.containsKey(sfField)){
                double nodeOrder = xmlStructure.Node_Order__c;
                //check if value from query is null
                if(FieldValues.get(sfField) != null){
                    String xmlFullName = xmlStructure.XML_Full_Name__c;
                    String replacement = String.ValueOf(FieldValues.get(sfField));
                    String newLine = xmlFullName.replace(sfField, replacement);
                    finalXmlMap.put(nodeOrder, newLine);
                }
                else if(FieldValues.get(sfField) == null){
                    finalXmlMap.put(xmlStructure.Node_Order__c, xmlStructure.XML_Full_Name__c);
                }
            }
            //if SCFieldMap does not contain sffield, the field value is null. Replace null value with just tags.
            else if(!FieldValues.ContainsKey(sfField)){
                String empty = '';
                String replacement = xmlStructure.XML_Full_Name__c.replace(sfField, empty);
                finalXmlMap.put(xmlStructure.Node_Order__c, replacement);
            }
        }
        else if(xmlStructure.Hardcoded_Flag__c == true){
            finalXmlMap.put(xmlStructure.Node_Order__c, xmlStructure.XML_Full_Name__c);
        }
    }
    
    //Use the new node list to build xml string.
    newNodeList.sort();
    List<String>finalXML = new List<String>();
    for(Double n : newNodeList){
        finalXML.add(finalXmlMap.get(n));
    }
    for(String s : finalXML){
        xmlString = xmlString + s;
    }
    
    //Pass the finalXML string, and the interface to the Callout class.
    String interfaceDetail = 'InterfaceID';
    Outbound_Integration_Callout.HttpMethod(xmlString, interfaceDetail);
    
}
}
}
