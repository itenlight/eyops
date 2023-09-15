xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace e553="urn:espa:v6:library:e553";

(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";

declare function e553:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function e553:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};

declare function e553:getXrewseisCountPerUser($inbound as element()) as element(){
 let $Xrewsis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                      'Select count(id_xrdel) AS EKKR 
                       From KPS6_XREOSEIS_DELTIA 
                       Where isxys_flg=1 
                          and kps6_core.get_obj_status (object_id, object_category_id) not in (300,306) 
                          and upper(user_name) = upper(?)', e553:get-user($inbound))
 return                          
 <Xrewsis xmlns="http://espa.gr/v6/e553">
  <temp>1</temp>
  <ekkremotitesCount>{fn:data($Xrewsis//*:EKKR)}</ekkremotitesCount>
 </Xrewsis>
};
