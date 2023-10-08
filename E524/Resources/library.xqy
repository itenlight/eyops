xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace e524-lib="http://espa.gr/v6/e524/lib";

declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace error="urn:espa:v6:library:error";


declare function e524-lib:if-empty( $arg as item()? ,$value as item()* )  as item()* {
  if (string($arg) != '') then 
    data($arg)
  else $value
 } ;

declare function e524-lib:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function e524-lib:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};


