xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace generic="urn:espa:v6:library:generic";

(: Δηλώσεις namespaces OSB  :)
(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";

declare function generic:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function generic:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};

declare function generic:GetKatastaseisDeltioy($inbound as element()) as element(){
let $KatastaseisDeltiou := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                    "Select OBJECT_STATUS_ID, Decode(?,'gr',OBJECT_STATUS_NAME,OBJECT_STATUS_NAME_EN) OBJECT_STATUS_NAME, OBJECT_STATUS_NAME_EN
                     from V6_OBJ_STATUS_LOOK 
                     Where OBJECT_CATEGORY_ID=?", generic:get-lang($inbound),
                     xs:unsignedShort($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="CategoryID"]/@value))
return
 
  <KatastaseisDeltioy xmlns="http://espa.gr/v6/generic">
  {if ($KatastaseisDeltiou/node()) then 
    for $Katastasi in $KatastaseisDeltiou
     return 
      <KatastasiDeltioy>
        <objectStatusId>{fn:data($Katastasi//*:OBJECT_STATUS_ID)}</objectStatusId>
        <objectStatusName>{fn:data($Katastasi//*:OBJECT_STATUS_NAME)}</objectStatusName>
      </KatastasiDeltioy>
      else <KatastasiDeltioy/>
    }
    </KatastaseisDeltioy>
  
};

declare function generic:GetLastUserAction($inbound as element()) as element(){
 let $LastUserAction := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                         'select * from KPS6_LOG_USER_ACTIONS 
                          WHERE LOG_USER_ACTION_ID =(SELECT MAX(LOG_USER_ACTION_ID) 
                           FROM KPS6_LOG_USER_ACTIONS 
                           WHERE OBJECT_CATEGORY_ID =? 
                             AND OBJECT_ID = ?)',
                         xs:unsignedShort($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="categoryId"]/@value),
                         xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="id"]/@value))
 return
  <LastUserAction xmlns="http://espa.gr/v6/generic">
   <id>{xs:unsignedLong($LastUserAction//*:LOG_USER_ACTION_ID)}</id>
   <objectCategoryId>{fn:data($LastUserAction//*:OBJECT_CATEGORY_ID)}</objectCategoryId>
   <objectId>{xs:unsignedLong($LastUserAction//*:OBJECT_ID)}</objectId>
   <actionCategoryId>{fn:data($LastUserAction//*:ACTION_CATEGORY_ID)}</actionCategoryId>
   <userName>{fn:data($LastUserAction//*:USER_NAME)}</userName>
   <dateAction>{fn:data($LastUserAction//*:DATE_ACTION)}</dateAction>
   <commentsAction>{fn:data($LastUserAction//*:COMMENTS_ACTION)}</commentsAction>
  </LastUserAction>
};

declare function generic:PostNewVersion($body as element()) as element(){
  let $NewVersion := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                    'SELECT  
                      KPS6_ERGORAMA_INFO.GET_EKDOSH(?,?,?) nea_ekdosh,
                      KPS6_ERGORAMA_INFO.GET_YPOEKDOSH(?,?,?) nea_ypoekdosh 
                     FROM dual',
                     xs:unsignedInt($body//*:id), 
                     xs:unsignedShort($body//*:categoryId), 
                     xs:unsignedInt($body//*:kathgoria_ekdoshs),
                     xs:unsignedInt($body//*:id), 
                     xs:unsignedShort($body//*:categoryId), 
                     xs:unsignedInt($body//*:kathgoria_ekdoshs))
  return                     
   <NewVersion xmlns="http://espa.gr/v6/generic">
    <id>1</id>
    <neaEkdosh>{fn:data($NewVersion//*:NEA_EKDOSH)}</neaEkdosh>
    <neaYpoekdosh>{fn:data($NewVersion//*:NEA_YPOEKDOSH)}</neaYpoekdosh>
   </NewVersion>
};
