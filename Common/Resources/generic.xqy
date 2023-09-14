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
<KatastaseisDeltioy xmlns="http://espa.gr/v6/generic">
{for $Katastasi in fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                    "Select OBJECT_STATUS_ID, Decode(?,'gr',OBJECT_STATUS_NAME,OBJECT_STATUS_NAME_EN) OBJECT_STATUS_NAME, OBJECT_STATUS_NAME_EN
                     from V6_OBJ_STATUS_LOOK 
                     Where OBJECT_CATEGORY_ID=?", generic:get-lang($inbound),
                     xs:unsignedShort($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="CategoryID"]/@value))
 return 
  <KatastasiDeltioy>
    <objectStatusId>{fn:data($Katastasi//*:OBJECT_STATUS_ID)}</objectStatusId>
    <objectStatusName>{fn:data($Katastasi//*:OBJECT_STATUS_NAME)}</objectStatusName>
    <objectStatusNameEn>{fn:data($Katastasi//*:OBJECT_STATUS_NAME_EN)}</objectStatusNameEn>
  </KatastasiDeltioy>
  }
</KatastaseisDeltioy>
};
