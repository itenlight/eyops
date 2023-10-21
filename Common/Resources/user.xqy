xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace user="urn:espa:v6:library:user";

(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";

declare function user:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function user:get-username($inbound as element()) as xs:string{
  xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};

declare function user:is-DiaxistikiArxi($inbound as element()) as element() {
  let $Username := xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
  let $SSOKatig  := xs:unsignedByte(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                        'select RLS7_SECURITY.GETSSOUSERKATHG(?) as KATHG 
                                        from dual',$Username)//*:KATHG)
                                        
  return
  <Response xmlns="http://espa.gr/v6/user">
   {if ($SSOKatig>1) then
    <result>true</result>
   else <result>false</result>}
  </Response>
   
};

declare function user:get-OAM-Cookie($inbound as element()) as element(){
  <Response xmlns="http://espa.gr/v6/user">
    <userName>
      {fn:data($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)}
    </userName>
  </Response>
  
};

declare function user:is-Controller($inbound as element()) as element() {
 let $Username   := xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
 let $Controller  := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                        'select (SELECT NVL(controller,0) 
                                                 FROM APPL6_USERS 
                                                 WHERE Upper(User_name)=Upper(?)) CONTROLLER from dual',
                                        $Username)
                                        
  return   
     if ($Controller//*:CONTROLLER/node() and fn:data($Controller//*:CONTROLLER)=1 ) then
      <Controller xmlns="http://espa.gr/v6/user">true</Controller>
     else <Controller xmlns="http://espa.gr/v6/user">false</Controller>   
};

declare function user:get-User-Kodikos-Forea($inbound as element()) as element(){
  let $Username    := xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
  let $KodikosForea := xs:unsignedInt(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                        'Select kps6_core.get_user_kodikos_forea(?) KODIKOS_FOREA from dual',
                                        $Username)//*:KODIKOS_FOREA)
  return
  <Response xmlns="http://espa.gr/v6/user">
    <kodikosForea>{$KodikosForea}</kodikosForea>
  </Response>
  
};

declare function user:get-User-Category($inbound as element()) as element() {
 let $Username    := xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
 let $UserCategory := xs:unsignedShort(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                        'Select RLS7_SECURITY.GETSSOUSERKATHG(?) USER_CATEGORY from dual',
                                        $Username)//*:USER_CATEGORY)
 return
 <UserCategory xmlns="http://espa.gr/v6/user">{$UserCategory}</UserCategory>
 };
