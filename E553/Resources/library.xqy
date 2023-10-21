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


declare function e553:GetDeltiaForFilter($inbound as element()) as element(){
<E553Response xmlns="http://espa.gr/v6/e553">
 {
 let $Deltia := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                      'SELECT object_category_id, 
                              Case When Upper(?)=''GR'' Then object_category_name 
                                   Else  Acronym_EN End object_category_name 
                      FROM kps6_object_categories 
                      WHERE object_category_id IN (101, 135, 103, 105, 130, 167, 182) 
                      UNION 
                      SELECT 0 AS object_category_id, 
				Case When Upper(?)=''GR'' then ''Όλα τα δελτία''  Else ''All forms'' End object_category_name 
                      FROM DUAL 
                      ORDER BY 1', e553:get-lang($inbound), e553:get-lang($inbound))
 return 
 if (fn:not($Deltia/node())) then <Row/>
 else
 for $Deltio in $Deltia return
   <Row>
    <objectCategoryId>{fn:data($Deltio//*:OBJECT_CATEGORY_ID)}</objectCategoryId>
    <objectCategoryName>{fn:data($Deltio//*:OBJECT_CATEGORY_NAME)}</objectCategoryName>
   </Row>
 }
 </E553Response>
};

