xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace e524-lib="http://espa.gr/v6/e524/lib";

declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace error="urn:espa:v6:library:error";
declare namespace e524="http://espa.gr/v6/e524";


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

declare function e524-lib:create-empty() as element(){
 <E524Response xmlns="http://espa.gr/v6/e524">
 
 <DATA >
      <Kps6ChecklistsDeltioy>
         <idChecklist/>
         <checklistEkdosh/>
         <checklistYpoekdosh/>
         <checklistType/>
         <objectCategoryId/>
         <checklistDate/>
         <eishghsh/>
         <bathmologia/>
         <bathmologisiFlag/>
         <flagAksiologhsh/>
         <parathrhseis/>
         <keimeno/>
         <katastash/>
         <protokolloArithmos/>
         <protokolloDate/>
         <sxoliaEyd/>
         <sxoliaYops/>
         <kodikosChecklistDeltioy/>
         <kodikosMis/>
         <deadlineDate/>
         <dikaioyxosTexnikaErga/>
         <dikaioyxosPromYpiresies/>
         <dikaioyxosIdiaMesa/>
         <sxoliaAksiolDioik/>
         <epanypobolhTdpFlg/>
         <listValueName/>
         <katastashMis/>
         <aaProsklhshs/>
         <foreasEgkrishs/>
         <kathgoriaEkdoshs/>
         <ekdoshSxolia/>
         <ekdDiorthoshFlg/>
         <ekdEpanypoboliFlg/>
         <ekdEpistrofiFlg/>
         <ekdForeasFlg/>
         <objectCategoryDeltiou/>
         <flagAksiologhsh/>
         <Kps6ChecklistsDeltioyUsers/>
         <kps6Tdp>
            <idTdp/>
            <titlos/>
            <dateAithshsEyd/>
            <ekdoshTdp/>
         </kps6Tdp>
         <kps6GenerateDocReport/>
         <Kps6ChecklistsEparkeia/>
         <Kps6DeltioErothmata/>
      </Kps6ChecklistsDeltioy>
   </DATA>
   <actionCode/>
   <comments/>
   <combineChecks>1</combineChecks>
   </E524Response>
};


