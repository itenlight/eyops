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
 
 declare function e524-lib:right-trim($arg as xs:string?) as xs:string {
   replace($arg,'\s+$','')
 } ;

declare function e524-lib:get-lang($inbound as element()) as xs:string{
  fn:upper-case(fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2))
};

declare function e524-lib:get-user($inbound as element()) as xs:string{
 fn:upper-case(xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value))
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

declare function  e524-lib:search-deltio($id as xs:unsignedInt, $username as xs:string, $lang as xs:string) as element(){

 let $Deltio := fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('Deltio'),
    'SELECT ID_CHECKLIST,  dd.ID_DOCREPORT,  DECODE (checklist_type,  57001, 148,  57002, 149,  NULL) OBJECT_CATEGORY_ID,  dd.OBJECT_ID,   
       dd.APOSTOLEAS,  dd.DIEYTHYNSH,  dd.SYNHMMENA,  dd.KOINOPOIHSH,  dd.ESOT_DIANOMH,  dd.APODEKTHS,  dd.THESH_TEL_YPOGR,    
       dd.NAME_TEL_YPOGR,  dd.ID_LOGO,  dd.POLH,  dd.PROS,  dd.MANUAL_CHANGE,  k.id_tdp,  CHECKLIST_EKDOSH,  CHECKLIST_YPOEKDOSH, 
       TITLOS,  TITLOS_KSENOS,  
       NVL ( kps6_core.Get_Obj_Status_Desc (a.id_CHECKLIST, DECODE (checklist_type,  57001, 148,  57002, 149,  NULL)),NULL) KATASTASH,  
       NVL (kps6_core.Get_Obj_Status_Desc_en (a.id_CHECKLIST,DECODE (checklist_type,  57001, 148,  57002, 149,  NULL)),NULL) KATASTASH_EN,   
       K.DATE_AITHSHS_EYD,  BATHMOLOGIA,  CHECKLIST_DATE,  CHECKLIST_TYPE,   
       DEADLINE_DATE,  DIKAIOYXOS_IDIA_MESA,  DIKAIOYXOS_PROM_YPIRESIES,  DIKAIOYXOS_TEXNIKA_ERGA,  EISHGHSH,  
       EPANYPOBOLH_TDP_FLG, ID_OBJECT,  KEIMENO,  KODIKOS_CHECKLIST_DELTIOY,  a.KODIKOS_MIS,  
       PARATHRHSEIS,   PROTOKOLLO_ARITHMOS,  PROTOKOLLO_DATE,  SXOLIA_AKSIOL_DIOIK,  SXOLIA_EYD,  
       SXOLIA_YOPS,  
       (select LIST_VALUE_NAME from KPS6_LIST_CATEGORIES_VALUES  where  list_value_id = a.EISHGHSH) as LIST_VALUE_NAME,  
       (select LIST_VALUE_NAME_EN from KPS6_LIST_CATEGORIES_VALUES  where  list_value_id = a.EISHGHSH) as LIST_VALUE_NAME_EN,  
       a.KATHGORIA_EKDOSHS,   a.EKD_DIORTHOSH_FLG,   a.EKD_EPANYPOVOLH_FLG,   a.EKD_EPISTROFI_FLG,   a.EKD_FOREAS_FLG,   
       a.EKD_LOIPA_FLG,   a.EKDOSH_SXOLIA,   a.FLAG_BATHMOLOGISI,   101  AS category_tdp,   
       (SELECT P.FLAG_AKSIOLOGHSH 
       FROM kps6_tdp A, kps6_prosklhseis P  
       WHERE A.aa_prosklhshs = P.KODIKOS_PROSKL_FOREA 
         AND p.id_prosklhshs =(SELECT id_prosklhshs   
                               FROM kps6_prosklhseis  
                               WHERE kodikos_proskl_forea = p.kodikos_proskl_forea 
                                 AND obj_isxys = 1) 
                                 AND a.id_tdp = k.id_tdp)  AS FLAG_AKSIOLOGHSH   
      FROM kps6_CHECKLISTS_DELTIOY a ,   KPS6_TDP k,KPS6_GENERATE_DOC_REPORT dd  
      WHERE K.ID_TDP(+) = a.ID_OBJECT    
        AND a.id_checklist = ?    
        AND dd.OBJECT_ID(+) = a.id_checklist    
        AND DD.OBJECT_CATEGORY_ID(+) =  DECODE (checklist_type,  57001, 148,  57002, 149,  NULL)', $id)
        
   let $Users :=  fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('Users'),
         'select c.ID_CHECKLIST_USERS, ID_XEIRISTH, c.TYPE_USER_FLAG, 
          CASE 
           WHEN nvl(c.TYPE_USER_FLAG,0) = 1 THEN 
                (SELECT ONOMASIA_SYNERGATH 
                 FROM KPS6_SYNERGATES 
                 WHERE to_char(ID_SYNERGATH) = c.ID_XEIRISTH) 
           ELSE onoma||''  ''||epitheto 
           END ONOMA, 
           CASE 
            WHEN c.TYPE_USER_FLAG = 1 THEN '''' 
            ELSE EPITHETO 
           END  EPITHETO, 
           CASE 
            WHEN c.TYPE_USER_FLAG = 1 THEN ''Μη Διαθέσιμο''
            ELSE NVL (AR_TAYTOTHTAS, ''Μη Διαθέσιμο'') 
           END  AR_TAYTOTHTAS,
           CASE 
            WHEN c.TYPE_USER_FLAG = 1 THEN ''Not Available'' 
            ELSE NVL (AR_TAYTOTHTAS, ''Not Available'')  
           END  AR_TAYTOTHTAS_EN,
           CASE 
            WHEN c.TYPE_USER_FLAG = 1  THEN 
             (SELECT NVL (EMAIL_SYNERGATH, ''Μη Διαθέσιμο'') 
              FROM KPS6_SYNERGATES 
              WHERE ID_SYNERGATH = c.ID_XEIRISTH) 
            ELSE NVL (EMAIL, ''Μη Διαθέσιμο'') 
           END  EMAIL, 
           CASE 
            WHEN c.TYPE_USER_FLAG = 1  THEN 
             (SELECT NVL (EMAIL_SYNERGATH, ''Not Available'') 
              FROM KPS6_SYNERGATES 
              WHERE ID_SYNERGATH = c.ID_XEIRISTH) 
             ELSE  NVL (EMAIL, ''Not Available'') 
            END EMAIL_EN, aa.TELEPHONE, aa.kodikos_forea, 
            (select PLHRHS_PERIGRAFH from c_foreis where kodikos_systhmatos = aa.kodikos_forea) kodikos_forea_descr, 
            (select PLHRHS_PERIGRAFH_en from c_foreis where kodikos_systhmatos = aa.kodikos_forea) kodikos_forea_descr_en 
          FROM kps6_CHECKLISTS_DELTIOY_USERS c, appl6_users aa
          where aa.user_name(+) = c.ID_XEIRISTH  
            and id_checklist= ? ',$id)
    let $ListaEparkeia :=  fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('Eparkeia'),
            'Select * From Kps6_Checklists_Eparkeia Where ID_CHECKLIST = ?',$id)
   return   
   <E524Response xmlns="http://espa.gr/v6/e524">
    <ERROR_CODE/>
    <ERROR_MESSAGE/>
    <DATA>
      <Kps6ChecklistsDeltioy>
        <idChecklist>{fn:data(($Deltio//*:ID_CHECKLIST)[1])}</idChecklist>
        <checklistEkdosh>{fn:data($Deltio//*:CHECKLIST_EKDOSH)}</checklistEkdosh>
        <checklistYpoekdosh>{fn:data($Deltio//*:CHECKLIST_YPOEKDOSH)}</checklistYpoekdosh>
        <checklistType>{fn:data($Deltio//*:CHECKLIST_TYPE)}</checklistType>
        <objectCategoryId>{fn:data($Deltio//*:CATEGORY_TDP)}</objectCategoryId>
        <checklistDate>{fn:data($Deltio//*:CHECKLIST_DATE)}</checklistDate>
        <eishghsh>{fn:data($Deltio//*:EISHGHSH)}</eishghsh>
        <bathmologia>{fn:data($Deltio//*:BATHMOLOGIA)}</bathmologia>
        <bathmologisiFlag>{fn:data($Deltio//*:FLAG_BATHMOLOGISI)}</bathmologisiFlag>
        <parathrhseis>{fn:data($Deltio//*:PARATHRHSEIS)}</parathrhseis>
        <keimeno>{fn:data($Deltio//*:KEIMENO)}</keimeno>
        <katastash>{
            if (fn:upper-case($lang)='GR') 
            then fn:data($Deltio//*:KATASTASH) 
            else fn:data($Deltio//*:KATASTASH_EN) }
        </katastash>
        <protokolloArithmos>{fn:data($Deltio//*:PROTOKOLLO_ARITHMOS)}</protokolloArithmos>
        <protokolloDate>{fn:data($Deltio//*:PROTOKOLLO_DATE)}</protokolloDate>
        <sxoliaEyd>{fn:data($Deltio//*:SXOLIA_EYD)}</sxoliaEyd>
        <sxoliaYops>{fn:data($Deltio//*:SXOLIA_YOPS)}</sxoliaYops>
        <kodikosChecklistDeltioy>{fn:data($Deltio//*:KODIKOS_CHECKLIST_DELTIOY)}</kodikosChecklistDeltioy>
        <kodikosMis>{fn:data($Deltio//*:KODIKOS_MIS)}</kodikosMis>
        <deadlineDate>{fn:data($Deltio//*:DEADLINE_DATE)}</deadlineDate>
        <dikaioyxosTexnikaErga>{fn:data($Deltio//*:DIKAIOYXOS_TEXNIKA_ERGA)}</dikaioyxosTexnikaErga>
        <dikaioyxosPromYpiresies>{fn:data($Deltio//*:DIKAIOYXOS_PROM_YPIRESIES)}</dikaioyxosPromYpiresies>
        <dikaioyxosIdiaMesa>{fn:data($Deltio//*:DIKAIOYXOS_IDIA_MESA)}</dikaioyxosIdiaMesa>
        <sxoliaAksiolDioik>{fn:data($Deltio//*:SXOLIA_AKSIOL_DIOIK)}</sxoliaAksiolDioik>
        <epanypobolhTdpFlg>{fn:data($Deltio//*:EPANYPOBOLH_TDP_FLG)}</epanypobolhTdpFlg>
        <listValueName>{
            if (fn:upper-case($lang)='GR') 
            then fn:data($Deltio//*:LIST_VALUE_NAME) 
            else fn:data($Deltio//*:LIST_VALUE_NAME_EN) }
        </listValueName>
        <katastashMis>{
            if (fn:data($Deltio//*:KODIKOS_MIS)) then
             fn:data(fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('Katastasi'),
                'select kps6_core.get_obj_status_desc(?,1) as STATUS from dual ',
                xs:unsignedInt($Deltio//*:KODIKOS_MIS))//*:STATUS)
            else ()}
        </katastashMis>
        {if (fn:data($Deltio//*:ID_TDP)) then
         (<aaProsklhshs>
          {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('AA'),
              'select AA_PROSKLHSHS from kps6_tdp where ID_TDP = ?',
               xs:unsignedInt($Deltio//*:ID_TDP))//*:AA_PROSKLHSHS)}
         </aaProsklhshs>,
         <foreasEgkrishs>
         {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('AA'),
              'select KODIKOS_FOREA FROM KPS6_TDP_FOREIS where  KATHGORIA_FOREA_STO_ERGO=5288 and ID_TDP = ?',
               xs:unsignedInt($Deltio//*:ID_TDP))//*:KODIKOS_FOREA)}
         </foreasEgkrishs>)
         else (<aaProsklhshs/>,
               <foreasEgkrishs/>)}
        <kathgoriaEkdoshs>{fn:data($Deltio//*:KATHGORIA_EKDOSHS)}</kathgoriaEkdoshs>
        <ekdoshSxolia>{fn:data($Deltio//*:EKDOSH_SXOLIA)}</ekdoshSxolia>
        <ekdDiorthoshFlg>{fn:data($Deltio//*:EKD_DIORTHOSH_FLG)}</ekdDiorthoshFlg>
        <ekdEpanypoboliFlg>{fn:data($Deltio//*:EKD_EPANYPOVOLH_FLG)}</ekdEpanypoboliFlg>
        <ekdEpistrofiFlg>{fn:data($Deltio//*:EKD_EPISTROFI_FLG)}</ekdEpistrofiFlg>
        <ekdForeasFlg>{fn:data($Deltio//*:EKD_FOREAS_FLG)}</ekdForeasFlg>
        <objectCategoryDeltiou>{fn:data(($Deltio//*:OBJECT_CATEGORY_ID)[1])}</objectCategoryDeltiou>
        <flagAksiologhsh>{fn:data($Deltio//*:FLAG_AKSIOLOGHSH)}</flagAksiologhsh> 
        {if ($Users/node()) then
         for $User in $Users 
         return 
         <Kps6ChecklistsDeltioyUsers>
          <idChecklistUsers>{fn:data($User//*:ID_CHECKLIST_USERS)}</idChecklistUsers>        
          <userName>{fn:data($User//*:ID_XEIRISTH)}</userName>
          <typeUserFlag>{fn:data($User//*:TYPE_USER_FLAG)}</typeUserFlag>
          <onoma>{fn:data($User//*:ONOMA)}</onoma>
          <epitheto>{fn:data($User//*:EPITHETO)}</epitheto>         
          <perigrafh>{
            if (fn:upper-case($lang)='GR') 
            then fn:data($User//*:KODIKOS_FOREA_DESCR) 
            else fn:data($User//*:KODIKOS_FOREA_DESCR_EN)}
          </perigrafh> 
          <email>{
            if (fn:upper-case($lang)='GR') 
            then fn:data($User//*:EMAIL) 
            else fn:data($User//*:EMAIL_EN)}
          </email>
          <telephone>{fn:data($User//*:TELEPHONE)}</telephone>
          <kodikosForea>{fn:data($User//*:KODIKOS_FOREA)}</kodikosForea>
        </Kps6ChecklistsDeltioyUsers>
        else <Kps6ChecklistsDeltioyUsers/>
       }
       <kps6Tdp>
        <idTdp>{fn:data($Deltio//*:ID_TDP)}</idTdp>
        <titlos>{
        if (fn:upper-case($lang)='GR') 
            then fn:data($Deltio//*:TITLOS) 
            else fn:data($Deltio//*:TITLOS_KSENOS)}</titlos>
        <dateAithshsEyd>{fn:data($Deltio//*:DATE_AITHSHS_EYD)}</dateAithshsEyd>
        <ekdoshTdp>{
        if (fn:data($Deltio//*:ID_TDP)) then
         fn:data(fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('Ekdosh'),
              'select TDP_EKDOSH||''.''||TDP_YPOEKDOSH as EKDOSH from kps6_tdp where ID_TDP = ?',
               xs:unsignedInt($Deltio//*:ID_TDP))//*:EKDOSH)
        else ()}
        </ekdoshTdp>
       </kps6Tdp>
       {if ($Deltio/node()) then
         <kps6GenerateDocReport>
          <idDocReport>{fn:data($Deltio//*:ID_DOCREPORT)}</idDocReport>
          <objectCategoryId>{fn:data($Deltio//*:OBJECT_CATEGORY_ID[1])}</objectCategoryId>
          <objectId>{fn:data($Deltio//*:ID_CHECKLIST)}</objectId>
          <apostoleas>{fn:data($Deltio//*:APOSTOLEAS)}</apostoleas>
          <dieythynsh>{fn:data($Deltio//*:DIEYTHYNSH)}</dieythynsh>
          <synhmmena>{fn:data($Deltio//*:SYNHMMENA)}</synhmmena>
          <koinopoihsh>{fn:data($Deltio//*:KOINOPOIHSH)}</koinopoihsh>
          <esotDianomh>{fn:data($Deltio//*:ESOT_DIANOMH)}</esotDianomh>
          <apodekths>{fn:data($Deltio//*:APODEKTHS)}</apodekths>
          <theshTelYpogr>{fn:data($Deltio//*:THESH_TEL_YPOGR)}</theshTelYpogr>
          <nameTelYpogr>{fn:data($Deltio//*:NAME_TEL_YPOGR)}</nameTelYpogr>
          <idLogo>{fn:data($Deltio//*:ID_LOGO)}</idLogo>
          <polh>{fn:data($Deltio//*:POLH)}</polh>
          <pros>{fn:data($Deltio//*:PROS)}</pros>
          <manualChange>{fn:data($Deltio//*:MANUAL_CHANGE)}</manualChange>
         </kps6GenerateDocReport>
        else <kps6GenerateDocReport/>}
        {if ($ListaEparkeia/node()) then
         for $Eparkeia in $ListaEparkeia return
         <Kps6ChecklistsEparkeia>
          <idChecklistEparkeia>{fn:data($Eparkeia//*:idChecklistEpark)}</idChecklistEparkeia>
          <kodikosForea>{fn:data($Eparkeia//*:kodikosForea)}</kodikosForea>
          <dikaioyxosTexnikaErga>{fn:data($Eparkeia//*:dikaioyxosTexnikaErga)}</dikaioyxosTexnikaErga>
          <dikaioyxosPromYpiresies>{fn:data($Eparkeia//*:dikaioyxosPromYpiresies)}</dikaioyxosPromYpiresies>
          <dikaioyxosIdiaMesa>{fn:data($Eparkeia//*:dikaioyxosIdiaMesa)}</dikaioyxosIdiaMesa>
          <dikaioyxosAllo>{fn:data($Eparkeia//*:dikaioyxosAllo)}</dikaioyxosAllo>
          <eparkeiaFlag>{fn:data($Eparkeia//*:eparkeiaFlag)}</eparkeiaFlag>
          <sxoliaForea>{fn:data($Eparkeia//*:sxoliaForea)}</sxoliaForea>
         </Kps6ChecklistsEparkeia>
         else <Kps6ChecklistsEparkeia/>}
      </Kps6ChecklistsDeltioy>
    </DATA>
   </E524Response>
};

declare function e524-lib:extract-erotimata($payload as element(), $username as xs:string, $lang as xs:string) 
  as element() {
  <Root-Element xmlns="http://TargetNamespace.com/DeltioErotimatonv6RestService_PUTPOST_request">
   <USERNAME>{$username}</USERNAME>
   <PASSWOR/>
   <LANG>{$lang}</LANG>
   <DATA>
   {for $Erotima in $payload/*:Kps6DeltioErothmata return    
    <Kps6DeltioErothmata>
       <idDeler>{fn:data($Erotima/*:idDeler)}</idDeler>
       <objectCategoryId>{
        if (fn:data($payload/*:checklistType)='57001') 
        then 148 
        else 149
        }</objectCategoryId>
       <parentId>{fn:data($Erotima/*:parentId)}</parentId>
       <checklistType>{fn:data($Erotima/*:checklistType)}</checklistType>
       <idErothma>{fn:data($Erotima/*:idErothma)}</idErothma>
       <apanthshValue>{fn:data($Erotima/*:apanthshValue)}</apanthshValue>
       <apanthshDate>{fn:data($Erotima/*:apanthshDate)}</apanthshDate>
       <statusId>{fn:data($Erotima/*:statusId)}</statusId>
       <isxysFlg>{fn:data($Erotima/*:isxysFlg)}</isxysFlg>
       <isxysDate>{fn:data($Erotima/*:isxysDate)}</isxysDate>
       <objectId>
       {if (fn:data($Erotima/*:idDeler))
        then fn:data($Erotima/*:objectId)
        else fn:data($payload/*:idChecklist)}
        </objectId>
       <sxoliaYops>{fn:data($Erotima/*:sxoliaYops)}</sxoliaYops>
       <parathrhseis>{fn:data($Erotima/*:parathrhseis)}</parathrhseis>
       <alloKeimeno>{fn:data($Erotima/*:alloKeimeno)}</alloKeimeno>
    </Kps6DeltioErothmata>}
   </DATA>    
  </Root-Element>  
};

declare function e524-lib:prepare-input($payload as element()) as element(){
 
 <Kps6ChecklistsDeltioyCollection xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/top/AksiologisiService">
  <Kps6ChecklistsDeltioy>
    <idChecklist>{fn:data($payload/*:idChecklist)}</idChecklist>
    <checklistEkdosh>{fn:data($payload/*:checklistEkdosh)}</checklistEkdosh>
    <checklistYpoekdosh>{fn:data($payload/*:checklistYpoekdosh)}</checklistYpoekdosh>
    <checklistType>{fn:data($payload/*:checklistType)}</checklistType>
    <objectCategoryId>101</objectCategoryId>
    <idObject>{fn:data($payload/*:kps6Tdp/*:idTdp)}</idObject>
    <checklistDate>{fn:data($payload/*:checklistDate)}</checklistDate>
    <eishghsh>{fn:data($payload/*:eishghsh)}</eishghsh>
    <bathmologia>{fn:data($payload/*:bathmologia)}</bathmologia>
    <parathrhseis>{fn:data($payload/*:parathrhseis)}</parathrhseis>
    <keimeno>{fn:data($payload/*:keimeno)}</keimeno>
    <protokolloArithmos>{fn:data($payload/*:protokolloArithmos)}</protokolloArithmos>
    <protokolloDate>{fn:data($payload/*:protokolloDate)}</protokolloDate>
    <sxoliaEyd>{fn:data($payload/*:sxoliaEyd)}</sxoliaEyd>
    <sxoliaYops>{fn:data($payload/*:sxoliaYops)}</sxoliaYops>
    <kodikosChecklistDeltioy>{fn:data($payload/*:kodikosChecklistDeltioy)}</kodikosChecklistDeltioy>
    <kodikosMis>{fn:data($payload/*:kodikosMis)}</kodikosMis>
    <deadlineDate>{fn:data($payload/*:deadlineDate)}</deadlineDate>
    <dikaioyxosTexnikaErga>{fn:data($payload/*:dikaioyxosTexnikaErga)}</dikaioyxosTexnikaErga>
    <dikaioyxosPromYpiresies>{fn:data($payload/*:dikaioyxosPromYpiresies)}</dikaioyxosPromYpiresies>
    <dikaioyxosIdiaMesa>{fn:data($payload/*:dikaioyxosIdiaMesa)}</dikaioyxosIdiaMesa>
    <sxoliaAksiolDioik>{fn:data($payload/*:sxoliaAksiolDioik)}</sxoliaAksiolDioik>
    <epanypobolhTdpFlg>{fn:data($payload/*:epanypobolhTdpFlg)}</epanypobolhTdpFlg>
    <kathgoriaEkdoshs>{fn:data($payload/*:kathgoriaEkdoshs)}</kathgoriaEkdoshs>
    <ekdDiorthoshFlg>{fn:data($payload/*:ekdDiorthoshFlg)}</ekdDiorthoshFlg>
    <ekdEpanypovolhFlg>{fn:data($payload/*:ekdEpanypoboliFlg)}</ekdEpanypovolhFlg>
    <ekdEpistrofiFlg>{fn:data($payload/*:ekdEpistrofiFlg)}</ekdEpistrofiFlg>
    <ekdForeasFlg>{fn:data($payload/*:ekdForeasFlg)}</ekdForeasFlg>
    <ekdoshSxolia>{fn:data($payload/*:ekdoshSxolia)}</ekdoshSxolia>
    <flagBathmologisi>{fn:data($payload/*:bathmologisiFlag)}</flagBathmologisi>
    <kps6ChecklistsEparkeiaCollection>
    {for $Eparkeia in $payload/*:Kps6ChecklistsEparkeia return
     <Kps6ChecklistsEparkeia> 
       <idChecklistEpark>{fn:data($Eparkeia/*:idChecklistEparkeia)}</idChecklistEpark>
       <kodikosForea>{fn:data($Eparkeia/*:kodikosForea)}</kodikosForea>
       <dikaioyxosTexnikaErga>{fn:data($Eparkeia/*:dikaioyxosTexnikaErga)}</dikaioyxosTexnikaErga>
       <dikaioyxosPromYpiresies>{fn:data($Eparkeia/*:dikaioyxosPromYpiresies)}</dikaioyxosPromYpiresies>
       <dikaioyxosIdiaMesa>{fn:data($Eparkeia/*:dikaioyxosIdiaMesa)}</dikaioyxosIdiaMesa>
       <dikaioyxosAllo>{fn:data($Eparkeia/*:dikaioyxosAllo)}</dikaioyxosAllo>
       <eparkeiaFlag>{fn:data($Eparkeia/*:eparkeiaFlag)}</eparkeiaFlag>
       <sxoliaForea>{fn:data($Eparkeia/*:sxoliaForea)}</sxoliaForea>
     </Kps6ChecklistsEparkeia>
    }
    </kps6ChecklistsEparkeiaCollection>
    <kps6ChecklistsDeltioyUsersCollection>
    {for $User in $payload/*:Kps6ChecklistsDeltioyUsers return
     <Kps6ChecklistsDeltioyUsers>
      <idChecklistUsers>{fn:data($User/*:idChecklistUsers)}</idChecklistUsers>
      <idXeiristh>{fn:data($User/*:userName)}</idXeiristh>
      <typeUserFlag>{fn:data($User/*:typeUserFlag)}</typeUserFlag>
     </Kps6ChecklistsDeltioyUsers>
    }
    </kps6ChecklistsDeltioyUsersCollection>
   </Kps6ChecklistsDeltioy>
 </Kps6ChecklistsDeltioyCollection>
 

};

declare function e524-lib:GetKodikosMisList($KodikosMis as element()?, 
                                           $ChecklistID as xs:unsignedLong, 
                                           $Lang as xs:string) as element(){
 <E524Response xmlns="http://espa.gr/v6/e524">
 {let $Predicate   := xs:string(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('QueryPredcate'),
                              'select rls7_security.fgetaccesskps6_kodikos_mis(''I'', 148, 0) from dual'))
  let $ListakodikonMis :=  if (fn:data($KodikosMis)) then
        fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-Mis'),
                  fn:concat('with stadio as ( SELECT A.ID_TDP,A.KODIKOS_MIS,A.tdp_ekdosh||''.''||A.tdp_ypoekdosh ekdosh_tdp,A.titlos, 
                    A.titlos_ksenos, A.date_aithshs_eyd, A.aa_prosklhshs, P.KODIKOS_FOREA, P.FLAG_AKSIOLOGHSH, 
                    (select kps6_core.get_obj_status(A.KODIKOS_MIS,1 ) from dual) katastash_kod 
                     FROM kps6_tdp A , kps6_prosklhseis P 
                     where a.kodikos_mis = nvl(?, a.kodikos_mis)
                      and a.tdp_ekdosh !=0
                      and A.aa_prosklhshs= P.KODIKOS_PROSKL_FOREA and p.obj_isxys =1 
                      and nvl(A.obj_status_id ,300)> 300 and A.EPIXEIRIMATIKOTITA !=5243  
                      and (select MASTER6.kps6_core.get_obj_status (a.kodikos_mis, 1) from dual) = 
                                                             decode(?,57001,201,57002,202)
                      And A.kodikos_mis not in (SELECT c.kodikos_mis 
                                                FROM kps6_checklists_deltioy c 
                                                WHERE c.CHECKLIST_Type = ? 
                                                  And c.OBJECT_CATEGORY_ID=101 
                                                  and c.kodikos_mis=a.kodikos_mis )
                      order by a.kodikos_mis desc , a.id_tdp desc)
                      select ID_TDP,KODIKOS_MIS, ekdosh_tdp,
                      Case When Upper(?)=''GR'' Then titlos Else titlos_ksenos End Titlos, 
                      date_aithshs_eyd, aa_prosklhshs, KODIKOS_FOREA, FLAG_AKSIOLOGHSH, katastash_kod,
                      (select Case When Upper(?)=''GR'' then object_status_name else object_status_name_en End  
                       from kps6_object_category_status
                           where object_category_id=1 
                           and object_status_id= katastash_kod) katastash
                      from stadio where ',$Predicate),
                xs:unsignedInt($KodikosMis),$ChecklistID, $ChecklistID, $Lang,$Lang) 
      else  fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-Mis'),
                  fn:concat('with stadio as ( SELECT A.ID_TDP,A.KODIKOS_MIS,A.tdp_ekdosh||''.''||A.tdp_ypoekdosh ekdosh_tdp, 
                      A.titlos, A.titlos_ksenos, A.date_aithshs_eyd, A.aa_prosklhshs, P.KODIKOS_FOREA, P.FLAG_AKSIOLOGHSH, 
                      (select kps6_core.get_obj_status(A.KODIKOS_MIS,1 ) from dual) katastash_kod 
                      FROM kps6_tdp A , kps6_prosklhseis P 
                      where A.aa_prosklhshs= P.KODIKOS_PROSKL_FOREA 
                        and p.id_prosklhshs=(select kps6_pros_package.get_last_prosklhsh(p.kodikos_proskl_forea) from dual) 
                        and nvl(A.obj_status_id ,300)> 300 and A.EPIXEIRIMATIKOTITA !=5243 
                        and (select MASTER6.kps6_core.get_obj_status (a.kodikos_mis, 1) from dual)=
                            decode(?,57001,201,57002,202) 
                      And A.kodikos_mis not in (SELECT c.kodikos_mis 
                                                FROM kps6_checklists_deltioy c 
                                                WHERE c.CHECKLIST_Type = ? 
                                                  And c.OBJECT_CATEGORY_ID=101 
                                                  and c.kodikos_mis=a.kodikos_mis ) 
                      order by a.kodikos_mis desc , a.id_tdp desc) 
                      select ID_TDP,KODIKOS_MIS, ekdosh_tdp, 
                      Case When Upper(?)=''GR'' Then titlos Else titlos_ksenos End Titlos, 
                      date_aithshs_eyd, aa_prosklhshs, KODIKOS_FOREA, FLAG_AKSIOLOGHSH, katastash_kod, 
                      (select Case When Upper(?)=''GR'' then object_status_name else object_status_name_en End 
                       from kps6_object_category_status 
                           where object_category_id=1 
                           and object_status_id= katastash_kod) katastash 
                      from stadio where ',$Predicate),$ChecklistID, $ChecklistID, $Lang, $Lang)  
  return
  if (fn:not($ListakodikonMis/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
  else
  for $Row in $ListakodikonMis  return            
  <Row>
    <kodikosMis>{fn:data($Row//*:ID_TDP)}</kodikosMis>
    <idTdp>{fn:data($Row//*:KODIKOS_MIS)}</idTdp>
    <ekdoshTdp>{fn:data($Row//*:EKDOSH_TDP)}</ekdoshTdp>
    <titlos>{fn:data($Row//*:TITLOS)}</titlos>
    <katastashPerig>{fn:data($Row//*:KATASTASH)}</katastashPerig>
    <dateAithshsEyd>{fn:data($Row//*:DATE_AITHSHS_EYD)}</dateAithshsEyd>
    <aaProsklhshs>{fn:data($Row//*:AA_PROSKLHSHS)}</aaProsklhshs>
    <kodikosForea>{fn:data($Row//*:KODIKOS_FOREA)}</kodikosForea>    
    <flagAksiologhsh>{fn:data($Row//*:FLAG_AKSIOLOGHSH)}</flagAksiologhsh>
  </Row>
 }
 </E524Response>
};

declare function e524-lib:GetMisListForView($KodikosMis as xs:unsignedInt,$Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListaKodikonMis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-Mis'),
      'SELECT distinct A.ID_TDP,A.KODIKOS_MIS,A.tdp_ekdosh||''.''||A.tdp_ypoekdosh as EKDOSH,
              Case When Upper(?)=''GR'' Then A.titlos Else A.titlos_ksenos End TITLOS, 
              A.date_aithshs_eyd, A.aa_prosklhshs,  
              P.KODIKOS_FOREA, P.FLAG_AKSIOLOGHSH,  
              A.obj_status_id as katastash_kod,  
              Case When Upper(?)=''GR'' Then s.OBJECT_STATUS_NAME   
                   Else s.OBJECT_STATUS_NAME_en 
              End KATASTASH_PERIG  
       FROM kps6_tdp A , kps6_prosklhseis P  , KPS6_OBJECT_CATEGORY_STATUS s 
       where  A.aa_prosklhshs= P.KODIKOS_PROSKL_FOREA 
         and p.id_prosklhshs=kps6_pros_package.get_last_prosklhsh(p.kodikos_proskl_forea) 
         and A.obj_status_id > 300 
         and s.OBJECT_CATEGORY_ID=101 AND a.obj_status_ID = s.OBJECT_STATUS_ID 
         And a.kodikos_mis = ? 
      order by  a.id_tdp desc',$Lang,$Lang,$KodikosMis)
  return
  if ($ListaKodikonMis/node()) then
  for $Row in $ListaKodikonMis return
   <Row>
    <kodikosMis>{fn:data($Row//*:ID_TDP)}</kodikosMis>
    <idTdp>{fn:data($Row//*:KODIKOS_MIS)}</idTdp>
    <ekdoshTdp>{fn:data($Row/*:EKDOSH)}</ekdoshTdp>
    <titlos>{fn:data($Row//*:TITLOS)}</titlos>
    <katastashPerig>{fn:data($Row//*:KATASTASH_PERIG)}</katastashPerig>
    <dateAithshsEyd>{fn:data($Row//*:DATE_AITHSHS_EYD)}</dateAithshsEyd>
    <aaProsklhshs>{fn:data($Row//*:AA_PROSKLHSHS)}</aaProsklhshs>
    <kodikosForea>{fn:data($Row//*:KODIKOS_FOREA)}</kodikosForea>    
    <flagAksiologhsh>{fn:data($Row//*:FLAG_AKSIOLOGHSH)}</flagAksiologhsh>
  </Row>
  else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
  
  }
  </E524Response>
};

declare function e524-lib:GetTdpListForFap($KodikosMis as xs:unsignedInt,$Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $TdpListaForFap := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-Mis'),
      'SELECT id_tdp,KODIKOS_MIS,tdp_ekdosh||''.''||tdp_ypoekdosh ekdosh,
       Case When Upper(?)=''GR'' Then titlos Else titlos_ksenos End Titlos,
       to_char(DATE_AITHSHS_EYD,''dd/mm/rrrr'') DATE_AITHSHS_EYD, 
       Case When Upper(?)=''GR'' Then NVL(kps6_core.Get_Obj_Status_Desc(id_tdp,101 ),'''') 
       Else NVL(kps6_core.Get_Obj_Status_Desc_En(id_tdp,101 ),'''') End  Katastash  
       FROM kps6_tdp 
       where  kps6_core.get_obj_status(KODIKOS_MIS,1 ) NOT IN (200,209,210) 
        and kps6_core.get_obj_status(id_tdp,101)>300 
        and kodikos_mis=?',$Lang,$Lang,$KodikosMis)
  return
  if ($TdpListaForFap/node()) then
  for $Row in $TdpListaForFap return
   <Row>
    <kodikosMis>{fn:data($Row//*:ID_TDP)}</kodikosMis>
    <idTdp>{fn:data($Row//*:KODIKOS_MIS)}</idTdp>
    <ekdoshTdp>{fn:data($Row/*:EKDOSH)}</ekdoshTdp>
    <titlos>{fn:data($Row//*:TITLOS)}</titlos>
    <katastashKod/>
    <katastashPerig>{fn:data($Row//*:KATASTASH_PERIG)}</katastashPerig>
    <dateAithshsEyd>{fn:data($Row//*:DATE_AITHSHS_EYD)}</dateAithshsEyd>    
  </Row>
  else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
  
  }
  </E524Response>
};

declare function e524-lib:GetEisigisiList($ChecklistID as xs:unsignedInt, $Lang) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $CheckLista := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-Mis'),
            'SELECT LIST_VALUE_KODIKOS_DISPLAY, LIST_VALUE_ID,
             Case When Upper(?)=''GR'' then LIST_VALUE_NAME Else LIST_VALUE_NAME_EN  End LIST_VALUE_NAME
             FROM KPS6_LIST_CATEGORIES_VALUES 
             WHERE IS_ACTIVE  = 1 
                AND LIST_CATEGORY_ID = decode(?, 57001, 574, 57002,575)',$Lang, $ChecklistID)
  return
  if ($CheckLista/node()) then
  for $Row in $CheckLista return
   <Row>
    <listValueId>{fn:data($Row//*:LIST_VALUE_ID)}</listValueId>
    <listValueKodikosDisplay>{fn:data($Row//*:LIST_VALUE_KODIKOS_DISPLAY)}</listValueKodikosDisplay>
    <listValueName>{fn:data($Row/*:LIST_VALUE_NAME)}</listValueName>   
  </Row>
  else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
  
  }
  </E524Response>
};

declare function e524-lib:GetListProskliseon($KodikosDeltiou as element()?, 
                                             $ChecklistID as xs:unsignedInt,  
                                             $Lang as xs:string) as element() {
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $Predicate   := xs:string(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('QueryPredcate'),
                              'select rls7_security.fgetaccesskps6_kodikos_mis(''I'', 148, 0) from dual'))
   let $ListaProskliseon := if ($KodikosDeltiou) then
     fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-proskliseon'),
     fn:concat('with ekd as 
              (select a.kodikos_mis, a.checklist_type, max_ekdosh, max(b.checklist_ypoekdosh) max_ypoekdosh, egkek, 
              (select count(id_checklist) 
              from KPS6_checklists_deltioy 
              where kodikos_mis=a.kodikos_mis 
                and kps6_core.get_obj_status(id_checklist, decode( ?,57001, 148,57002,149,-1)) in (302)) count_ekremeis 
              from (SELECT kodikos_mis, checklist_type, max(checklist_ekdosh) max_ekdosh, 1 egkek 
              FROM KPS6_checklists_deltioy 
              WHERE exists (select 1 from dual where kps6_CORE.get_ISXYON_DELTIO(kodikos_mis,decode( ?,57001, 148,57002,149,-1),304)!=-1) 
              group by kodikos_mis, checklist_type 
              union 
              select kodikos_mis, checklist_type,max(checklist_ekdosh) max_ekdosh, 0 egkek 
              FROM KPS6_checklists_deltioy 
              WHERE kps6_CORE.get_ISXYON_DELTIO(kodikos_mis,decode(?,57001, 148,57002,149,-1),304)=-1 
              group by kodikos_mis, checklist_type 
              order by max_ekdosh desc ) a, kps6_checklists_deltioy b 
              where a.kodikos_mis=b.kodikos_mis 
                and a.checklist_type=b.checklist_type 
                and max_ekdosh=b.checklist_ekdosh 
              group by a.kodikos_mis,a.checklist_type, max_ekdosh, egkek) 
             select q.kodikos_mis, t.tdp_ekdosh||''.''|| t.tdp_ypoekdosh as tdpekd, 
            Case When Upper(?)=''GR'' then decode ( ?, 57001,''Α (ΛΕΠ)'', 57002, ''Β (ΦΑΠ)'' )  
            Else decode (?, 57001,''Phase 1'', 57002, ''Phase 2'' ) End as Stadio, 
              w.checklist_ekdosh||''.''|| w.checklist_ypoekdosh as ekdosh_ypoekdosh, 
            (select nvl(kps6_core.Get_Obj_Status( w.id_checklist, decode( ?,57001, 148,57002,149,-1)), -1) from dual) as KATASTASH, 
           Case When Upper(?)=''GR'' then (select object_status_name from kps6_object_category_status 
                                          where object_category_id=decode( ?,57001, 148,57002,149,-1) 
                                             and object_status_id= 
                                               (select nvl(kps6_core.Get_Obj_Status( w.id_checklist, decode( ?,57001, 148,57002,149,-1)), 300) from dual))
            else (select object_status_name_en 
                  from kps6_object_category_status 
                  where object_category_id=decode(?,57001, 148,57002,149,-1) 
                    and object_status_id= (select nvl(kps6_core.Get_Obj_Status( w.id_checklist, 
                                           decode( ?,57001, 148,57002,149,-1)), 300) from dual)) End  as KATAST_DESC, 
        w.id_checklist, q.checklist_type, w.checklist_ekdosh, 
        case when (select kps6_CORE.get_ISXYON_DELTIO(w.kodikos_mis,decode(, 57001, 148,57002,149,-1),304) from dual)=W.id_checklist then 1 else 0 end isxys, 
        case when egkek=1 then max_ekdosh+1 else max_ekdosh end new_ekdosh, 
        case when egkek=1 then 0 else max_ypoekdosh+1 end new_ypoekdosh ,
        case when egkek=1 then 5722 else 5721 end type_NEW_ekd, max_ekdosh ||''.''|| max_ypoekdosh max_ekd ,count_ekremeis, 
        case when count_ekremeis=0 then case WHEN egkek=1 THEN 5722 else 5721 end 
             else -1 end ACTION_TYPE 
       from ekd q, kps6_checklists_deltioy w, kps6_tdp t 
       where q.kodikos_mis=w.kodikos_mis 
          and q.checklist_type=w.checklist_type 
          and t.id_tdp=w.id_object 
          and w.checklist_type= ? 
          and ',$Predicate),
            $ChecklistID,$ChecklistID,$ChecklistID,$Lang,$ChecklistID,$ChecklistID,
            $ChecklistID,$Lang,$ChecklistID,$ChecklistID,$ChecklistID,$ChecklistID,$ChecklistID)
  else fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lista-proskliseon'),
     fn:concat('with ekd as (select a.kodikos_mis, a.checklist_type, max_ekdosh, max(b.checklist_ypoekdosh) max_ypoekdosh, egkek, 
 (select count(id_checklist) from KPS6_checklists_deltioy where kodikos_mis=a.kodikos_mis and kps6_core.get_obj_status(id_checklist, decode( ?,57001, 148,57002,149,-1)) in (302)) count_ekremeis 
  from (SELECT kodikos_mis, checklist_type, max(checklist_ekdosh) max_ekdosh, 1 egkek FROM KPS6_checklists_deltioy WHERE exists (select 1 from dual where 
   kps6_CORE.get_ISXYON_DELTIO(kodikos_mis,decode(?,57001, 148,57002,149,-1),304)!=-1) group by kodikos_mis, checklist_type union select kodikos_mis, checklist_type,max(checklist_ekdosh) max_ekdosh, 0 egkek 
    FROM KPS6_checklists_deltioy WHERE kps6_CORE.get_ISXYON_DELTIO(kodikos_mis,decode( ?,57001, 148,57002,149,-1),304)=-1 group by kodikos_mis, checklist_type order by max_ekdosh desc ) a, kps6_checklists_deltioy b 
     where a.kodikos_mis=b.kodikos_mis and a.checklist_type=b.checklist_type and max_ekdosh=b.checklist_ekdosh group by a.kodikos_mis,a.checklist_type, max_ekdosh, egkek) 
      select q.kodikos_mis, t.tdp_ekdosh||''.''|| t.tdp_ypoekdosh as tdpekd, 
      Case When Upper(?)=''GR'' Then decode (?, 57001,''Α (ΛΕΠ)'', 57002, ''Β (ΦΑΠ)'' )  
           Else decode ( ?, 57001,''Phase 1'', 57002, ''Phase 2'' ) End  as Stadio,
      w.checklist_ekdosh||''.''|| w.checklist_ypoekdosh as ekdosh_ypoekdosh, 
 (select nvl(kps6_core.Get_Obj_Status( w.id_checklist, decode(?,57001, 148,57002,149,-1)), -1) from dual) as KATASTASH, 
  Case When Upper(?)=''GR'' Then (select object_status_name from kps6_object_category_status 
  where object_category_id=decode( ?,57001, 148,57002,149,-1) and object_status_id= (
  select nvl(kps6_core.Get_Obj_Status( w.id_checklist, decode( ?,57001, 148,57002,149,-1)), 300) from dual)) else 
   (select object_status_name_en from 
   kps6_object_category_status where object_category_id=decode( ?,57001, 148,57002,149,-1) and object_status_id= 
   (select nvl(kps6_core.Get_Obj_Status( w.id_checklist, 
 decode( ?,57001, 148,57002,149,-1)), 300) from dual)) End as KATAST_DESC, w.id_checklist, q.checklist_type, w.checklist_ekdosh, 
 case when (select kps6_CORE.get_ISXYON_DELTIO(w.kodikos_mis,decode( ?, 57001, 148,57002,149,-1),304) from dual)=W.id_checklist then 1 else 0 end isxys, 
 case when egkek=1 then max_ekdosh+1 else 
   max_ekdosh end new_ekdosh, case when egkek=1 then 0 else max_ypoekdosh+1 end new_ypoekdosh , 
   case when egkek=1 then 5722 else 5721 end type_NEW_ekd, max_ekdosh ||''.''|| max_ypoekdosh max_ekd ,count_ekremeis, 
  case when count_ekremeis=0 then case WHEN egkek=1 THEN 5722 else 5721 end else -1 end ACTION_TYPE from ekd q, kps6_checklists_deltioy w, kps6_tdp t 
 where q.kodikos_mis=w.kodikos_mis and q.checklist_type=w.checklist_type and t.id_tdp=w.id_object and w.checklist_type= ? and ',$Predicate),
 $ChecklistID,$ChecklistID,$ChecklistID,$Lang,$ChecklistID,$ChecklistID,$ChecklistID,
 $Lang,$ChecklistID,$ChecklistID,$ChecklistID,$ChecklistID,$ChecklistID,$ChecklistID)
  return
  if ($ListaProskliseon/node()) then
  for $Row in $ListaProskliseon return
   <Row>
    <idCheckList>{fn:data($Row//*:ID_CHECKLIST)}</idCheckList>
    <kodikosMis>{fn:data($Row//*:KODIKOS_MIS)}</kodikosMis>
    <tdpEkd>{fn:data($Row/*:TDPEKD)}</tdpEkd> 
    <stadio>{fn:data($Row/*:STADIO)}</stadio>   
    <checkListType>{fn:data($Row/*:CHECKLIST_TYPE)}</checkListType>   
    <checkListEkdosi>{fn:data($Row/*:CHECKLIST_EKDOSH)}</checkListEkdosi>   
    <ekdosiYpoekdosi>{fn:data($Row/*:EKDOSH_YPOEKDOSH)}</ekdosiYpoekdosi>  
    <katastasi>{fn:data($Row/*:KATASTASH)}</katastasi>
    <katastasiDesc>{fn:data($Row/*:KATAST_DESC)}</katastasiDesc>  
    <newEkdosi>{fn:data($Row/*:NEW_EKDOSH)}</newEkdosi>  
    <newYpoekdosi>{fn:data($Row/*:NEW_YPOEKDOSH)}</newYpoekdosi>  
    <maxEkd>{fn:data($Row/*:MAX_EKD)}</maxEkd>  
    <countEkremeis>{fn:data($Row/*:COUNT_EKREMEIS)}</countEkremeis>  
    <actionType>{fn:data($Row/*:ACTION_TYPE)}</actionType>  
    <typeNewEkd>{fn:data($Row/*:TYPE_NEW_EKD)}</typeNewEkd> 
    <isxys>{fn:data($Row/*:ISXYS)}</isxys>  
  </Row>
  else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
 }
  </E524Response>
};

declare function e524-lib:GetNewFapVersion($ChecklistID as xs:unsignedLong,
                                           $KatigoriaEndosis as xs:unsignedInt) as element()? {
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $NewFapVersion := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Fap-Version'),
            'SELECT 1 ID, KPS6_ERGORAMA_INFO.GET_EKDOSH( ?, 149, ?) nea_ekdosh, 
                    KPS6_ERGORAMA_INFO.GET_YPOEKDOSH( ?, 149, ?)  nea_ypoekdosh
             FROM dual',$ChecklistID,$KatigoriaEndosis,$ChecklistID,$KatigoriaEndosis)
   return 
    (
     <id>1</id>,
     <neaEkdosh>{fn:data($NewFapVersion/*:NEA_EKDOSH)}</neaEkdosh>,
     <neaYpoekdosh>{fn:data($NewFapVersion/*:NEA_YPOEKDOSH)}</neaYpoekdosh>
    )  
  }
  </E524Response>
};

declare function e524-lib:GetNewLepVersion($ChecklistID as xs:unsignedLong,
                                           $KatigoriaEndosis as xs:unsignedInt) as element() {
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $NewFapVersion := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Lep-Version'),
            'SELECT 1 ID, KPS6_ERGORAMA_INFO.GET_EKDOSH( ?, 148, ?) nea_ekdosh, 
                    KPS6_ERGORAMA_INFO.GET_YPOEKDOSH( ?, 148, ?)  nea_ypoekdosh
             FROM dual',$ChecklistID,$KatigoriaEndosis,$ChecklistID,$KatigoriaEndosis)
   return 
    (
     <id>1</id>,
     <neaEkdosh>{fn:data($NewFapVersion/*:NEA_EKDOSH)}</neaEkdosh>,
     <neaYpoekdosh>{fn:data($NewFapVersion/*:NEA_YPOEKDOSH)}</neaYpoekdosh>
    )
  }
  </E524Response>
};

declare function e524-lib:GetKodkousForeon($IDTdp as xs:unsignedInt, $Lang as xs:string){

   <E524Response xmlns="http://espa.gr/v6/e524">
   {let $ListaForeon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Foreis'),
      'select kodikos_forea, 
       Case When Upper(?)=''GR'' then (select perigrafh from c_foreis where tdp_foreis.kodikos_forea=c_foreis.kodikos_systhmatos)
            else (select perigrafh_en from c_foreis where tdp_foreis.kodikos_forea=c_foreis.kodikos_systhmatos) End perigrafh 
      from kps6_tdp_foreis tdp_foreis 
      where tdp_foreis.id_tdp= ? 
        and tdp_foreis.kathgoria_forea_sto_ergo in (5281,5282) 
        and tdp_foreis.kodikos_ypoergoy is null',$Lang,$IDTdp)
   return
   if ($ListaForeon/node()) then
   for $Row in $ListaForeon return 
   <Row>
    <kodikosForea>{fn:data($Row/*:KODIKOS_FOREA)}</kodikosForea>
    <perigrafh>{fn:data($Row/*:PERIGRAFH)}</perigrafh>
   </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
   </E524Response>   
};

declare function e524-lib:GetErotimata($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListaErotimaton := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Erotimata'),
      'Select DISTINCT  id_erothma ||list_value_id id_erot_list, id_erothma, list_value_id, 
       Case When Upper(?)=''GR'' Then list_value_name else list_value_name_en End list_value_name, 
       list_value_aa 
       from KPS6_CHECKLISTS_TEMPLATE b, KPS6_LIST_CATEGORIES_VALUES a  
       where a.list_category_id = b.list_category_id 
         and b.checklist_type in  (57148,57149)  
         and a.is_active = 1',$Lang)
   return
   if ($ListaErotimaton/node()) then
   for $Row in $ListaErotimaton return 
   <Row>
    <idErotList>{fn:data($Row/*:ID_EROT_LIST)}</idErotList>
    <idErothma>{fn:data($Row/*:ID_EROTHMA)}</idErothma>
    <listValueId>{fn:data($Row/*:LIST_VALUE_ID)}</listValueId>
    <listValueName>{fn:data($Row/*:LIST_VALUE_NAME)}</listValueName>
   </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  
  </E524Response> 
  
};

declare function e524-lib:GetApList($idEp as xs:unsignedInt, $Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListaAP := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('AP'),
      'select distinct axan.id_ep, axan.id_axona, axan.kodikos_axona, 
       Case When Upper(?)=''GR'' Then axan.titlos_ep Else axan.titlos_ep_en End titlos_ep, 
       Case When Upper(?)=''GR'' Then axan.titlos_axona Else axan.titlos_axona_en End titlos_axona 
       FROM v6_ep_axones_analysh_denorm  axan  
       WHERE axan.id_ep=nvl(?,axan.id_ep)',$Lang, $Lang, $idEp)
   return
   if ($ListaAP/node()) then
   for $Row in $ListaAP return 
   <Row>
    <kodikosAxona>{fn:data($Row/*:KODIKOS_AXONA)}</kodikosAxona>
    <titlosAxona>{fn:data($Row/*:TITLOS_AXONA)}</titlosAxona>
    <idAxona>{fn:data($Row/*:ID_AXONA)}</idAxona>
    <idEp>{fn:data($Row/*:ID_EP)}</idEp>
    <titlosEp>{fn:data($Row/*:TITLOS_EP)}</titlosEp>
   </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};


declare function e524-lib:GetEPList($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListaEP := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('AP'),
      'select distinct axan.id_ep, 
       Case When Upper(:pLang)=''GR'' Then axan.titlos_ep Else  axan.titlos_ep_en End titlos_ep
       from v6_ep_axones_analysh_denorm  axan order by axan.id_ep ',$Lang)
   return
   if ($ListaEP/node()) then
   for $Row in $ListaEP return 
   <Row>
    <kodikosForea>{fn:data($Row/*:KODIKOS_FOREA)}</kodikosForea>
    <perigrafh>{fn:data($Row/*:PERIGRAFH)}</perigrafh>
   </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetForeisEgrisiList($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListaForeon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Foreas'),
      'select distinct a.kodikos_forea, 
       Case When Upper(?)=''GR'' Then b.perigrafh Else b.perigrafh_en End perigrafh
       from KPS6_TDP_FOREIS a, c_foreis b 
       where a.kodikos_forea=b.kodikos_systhmatos 
       AND A.KATHGORIA_FOREA_STO_ERGO=5288',$Lang)
   return
   if ($ListaForeon/node()) then
   for $Row in $ListaForeon return 
   <Row>
    <kodikosForea>{fn:data($Row/*:KODIKOS_FOREA)}</kodikosForea>
    <perigrafh>{fn:data($Row/*:PERIGRAFH)}</perigrafh>
   </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetMis($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $ListMis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Mis'),
      'SELECT A.ID_TDP,A.KODIKOS_MIS, A.tdp_ekdosh||''.''||A.tdp_ypoekdosh as EKDOSH,
       Case When Upper(?)=''GR'' Then A.titlos Else A.titlos_ksenos End Titlos, 
       A.date_aithshs_eyd,  A.aa_prosklhshs, katast_mis.katastash_kod as katastash_kod, 
       Case When Upper(?)=''GR'' Then (select object_status_name  
                                          from kps6_object_category_status 
                                          where object_category_id = 1 
                                          and object_status_id =katast_mis.katastash_kod )
       Else  (select object_status_name_en  
              from kps6_object_category_status 
              where object_category_id = 1 
                and object_status_id =katast_mis.katastash_kod ) End  katastash_perig 
       FROM kps6_tdp A , KPS6_PROSKLHSEIS P,   
            (select u.object_id kodikos_mis, object_status_id katastash_kod  
             from kps6_status_updates u  
             where u.object_category_id = 1   
              and u.status_update_id =  (select  max(status_update_id) 
                                  from kps6_status_updates su 
                                  where su.object_category_id = 1 
                                    and su.object_id =  u.object_id  
                                  group by su.object_id ))   katast_mis 
      where  A.AA_PROSKLHSHS = P.KODIKOS_PROSKL_FOREA  
      AND P.OBJ_ISXYS = 1  
      AND A.obj_status_id > 300 
      and a.kodikos_mis = katast_mis.kodikos_mis 
      AND A.EPIXEIRIMATIKOTITA!=5243 
      order by a.kodikos_mis desc , a.id_tdp desc',$Lang, $Lang)
   return
   if ($ListMis/node()) then
   for $Row in $ListMis return 
    <Row>
    <kodikosMis>{fn:data($Row//*:ID_TDP)}</kodikosMis>
    <idTdp>{fn:data($Row//*:KODIKOS_MIS)}</idTdp>
    <ekdoshTdp>{fn:data($Row/*:EKDOSH)}</ekdoshTdp>
    <titlos>{fn:data($Row//*:TITLOS)}</titlos>
    <katastashKod>{fn:data($Row//*:KATASTASH_KOD)}</katastashKod>
    <katastashPerig>{fn:data($Row//*:KATASTASH_PERIG)}</katastashPerig>
    <dateAithshsEyd>{fn:data($Row//*:DATE_AITHSHS_EYD)}</dateAithshsEyd>    
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetVersionList($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $VersionList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Version'),
      'SELECT  ROWID, K.LIST_CATEGORY_ID, K.LIST_VALUE_ID, 
         Case When Upper(?)=''GR'' Then K.LIST_VALUE_NAME Else K.LIST_VALUE_NAME_EN End LIST_VALUE_NAME, 
         K.COMMENTS, K.LIST_VALUE_KODIKOS_DISPLAY, 
         K.LIST_VALUE_AA 
       FROM MASTER6.KPS6_LIST_CATEGORIES_VALUES K 
       WHERE LIST_CATEGORY_ID = 572
         AND IS_ACTIVE  = 1 
         AND K.LIST_VALUE_ID NOT IN 5725',$Lang)
   return
   if ($VersionList/node()) then
   for $Row in $VersionList return 
    <Row>
    <listValueId>{fn:data($Row//*:LIST_VALUE_ID)}</listValueId>
    <rowId>{fn:data($Row//*:ROWID)}</rowId>
    <listCategoryId>{fn:data($Row/*:LIST_CATEGORY_ID)}</listCategoryId>
    <listValueKodikosDisplay>{fn:data($Row//*:LIST_VALUE_KODIKOS_DISPLAY)}</listValueKodikosDisplay>
    <listValueName>{fn:data($Row//*:LIST_VALUE_NAME)}</listValueName>
    <listValueNameAa>{fn:data($Row//*:LIST_VALUE_AA)}</listValueNameAa>
    <comments>{fn:data($Row//*:COMMENTS)}</comments>
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetAllAxiologitesList($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $AksiologitesList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Version'),
      'select a.user_name, a.onoma||'' ''||a.epitheto onoma, a.telephone, a.email ,a.kodikos_forea, 
       Case When Upper(?)=''GR'' Then b.perigrafh Else b.perigrafh_en End perigrafh, 0 TYPE_USER_FLAG 
       from appl6_users a, c_foreis b 
       where a.kodikos_forea = b.kodikos_systhmatos (+) 
         AND NVL(A.FOREAS_KATHG,0)!=1 
       union 
       SELECT to_char(s.ID_SYNERGATH)  user_name, s.ONOMASIA_SYNERGATH onoma, NULL telephone, s.EMAIL_SYNERGATH email , s.KODIKOS_FOREA_EYD   kodikos_forea, 
       Case When Upper(?)=''GR'' Then bs.perigrafh Else bs.perigrafh_en End perigrafh, 1  TYPE_USER_FLAG 
       FROM KPS6_SYNERGATES s, c_foreis bs 
       where s.KODIKOS_FOREA_EYD = bs.kodikos_systhmatos (+) 
       order by  TYPE_USER_FLAG, onoma',$Lang,$Lang)
   return
   if ($AksiologitesList/node()) then
   for $Row in $AksiologitesList return 
    <Row>
    <userName>{fn:data($Row//*:USER_NAME)}</userName>
    <onoma>{fn:data($Row//*:ONOMA)}</onoma>
    <telephone>{fn:data($Row/*:TELEPHONE)}</telephone>
    <email>{fn:data($Row//*:EMAIL)}</email>
    <kodikosForea>{fn:data($Row//*:KODIKOS_FOREA)}</kodikosForea>
    <perigrafh>{fn:data($Row//*:PERIGRAFH)}</perigrafh>
    <typeUserFlag>{fn:data($Row//*:TYPE_USER_FLAG)}</typeUserFlag>
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetLepAxiologitesList($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $AksiologitesList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Version'),
      'Select distinct a.user_name, a.onoma onoma, a.epitheto epitheto, a.ar_taytothtas, a.email, a.kodikos_forea, 
       Case When Upper(?)=''GR'' Then b.perigrafh Else b.perigrafh_en End perigrafh
       from appl6_users a, c_foreis b, appl6_users c 
       where a.kodikos_forea = b.kodikos_systhmatos (+) 
       and a.kodikos_forea = c.kodikos_forea 
      AND NVL(A.FOREAS_KATHG,0)!=1',$Lang)
   return
   if ($AksiologitesList/node()) then
   for $Row in $AksiologitesList return 
    <Row>
    <userName>{fn:data($Row//*:USER_NAME)}</userName>
    <onoma>{fn:data($Row//*:ONOMA)}</onoma>
    <telephone>{fn:data($Row/*:TELEPHONE)}</telephone>
    <email>{fn:data($Row//*:EMAIL)}</email>
    <kodikosForea>{fn:data($Row//*:KODIKOS_FOREA)}</kodikosForea>
    <perigrafh>{fn:data($Row//*:PERIGRAFH)}</perigrafh>
    <typeUserFlag>{fn:data($Row//*:TYPE_USER_FLAG)}</typeUserFlag>
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:GetExoterikoipAxiologitesList() as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $AksiologitesList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Version'),
      'SELECT ID_SYNERGATH, ONOMASIA_SYNERGATH, EMAIL_SYNERGATH ,KODIKOS_FOREA_EYD 
       FROM KPS6_SYNERGATES')
   return
   if ($AksiologitesList/node()) then
   for $Row in $AksiologitesList return 
    <Row>
    <idSynergath>{fn:data($Row//*:ID_SYNERGATH)}</idSynergath>
    <onomasiaSynergath>{fn:data($Row//*:ONOMASIA_SYNERGATH)}</onomasiaSynergath>
    <emailSynergath>{fn:data($Row/*:EMAIL_SYNERGATH)}</emailSynergath>
    <kodikosForeaEyd>{fn:data($Row//*:KODIKOS_FOREA_EYD)}</kodikosForeaEyd>
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};

declare function e524-lib:LoadEnergeiaOpsOptions($Lang as xs:string) as element(){
  <E524Response xmlns="http://espa.gr/v6/e524">
  {let $OptionsList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Option'),
      'SELECT K.LIST_VALUE_AA, 
       Case When Upper(?)=''GR'' Then K.LIST_VALUE_NAME Else K.LIST_VALUE_NAME_EN End LIST_VALUE_NAME
       FROM MASTER6.KPS6_LIST_CATEGORIES_VALUES K 
       Where LIST_CATEGORY_ID  = 577 
         AND IS_ACTIVE  = 1 
       ORDER BY LIST_VALUE_AA ASC NULLS LAST',$Lang)
   return
   if ($OptionsList/node()) then
   for $Row in $OptionsList return 
    <Row>
    <listValueAa>{fn:data($Row//*:LIST_VALUE_AA)}</listValueAa>
    <listValueName>{fn:data($Row//*:LIST_VALUE_NAME)}</listValueName>
  </Row>
   else fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   }    
  </E524Response> 
};