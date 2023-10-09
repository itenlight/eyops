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
 
 declare function e524-lib:right-trim
  ( $arg as xs:string? )  as xs:string {
   replace($arg,'\s+$','')
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

declare function e524-lib:extract-erotimata($payload as element()) as element() {
  <ErotimataRequest xmlns="http://espa.gr/v6/e524">
   <USERNAME/>
   <LANG/>
   <DATA>
   {for $Erotima in $payload/*:Kps6DeltioErothmata return
    <Kps6DeltioErothmata>
       <idDeler>{fn:data($Erotima/*:idDeler)}</idDeler>
       <objectCategoryId>{fn:data($Erotima/*:objectCategoryId)}</objectCategoryId>
       <parentId>{fn:data($Erotima/*:parentId)}</parentId>
       <checklistType>{fn:data($Erotima/*:checklistType)}</checklistType>
       <idErothma>{fn:data($Erotima/*:idErothma)}</idErothma>
       <apanthshValue>{fn:data($Erotima/*:apanthshValue)}</apanthshValue>
       <apanthshDate>{fn:data($Erotima/*:apanthshDate)}</apanthshDate>
       <statusId>{fn:data($Erotima/*:statusId)}</statusId>
       <isxysFlg>{fn:data($Erotima/*:isxysFlg)}</isxysFlg>
       <isxysDate>{fn:data($Erotima/*:isxysDate)}</isxysDate>
       <objectId>{fn:data($Erotima/*:objectId)}</objectId>
       <sxoliaYops>{fn:data($Erotima/*:sxoliaYops)}</sxoliaYops>
       <parathrhseis>{fn:data($Erotima/*:parathrhseis)}</parathrhseis>
       <alloKeimeno>{fn:data($Erotima/*:alloKeimeno)}</alloKeimeno>
    </Kps6DeltioErothmata>}
   </DATA>    
  </ErotimataRequest>  
};

declare function e524-lib:prepare-input($payload as element()) as element(){
 
 <Kps6ChecklistsDeltioyCollection xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/top/AklsiologisiService">
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
    </kps6ChecklistsEparkeiaCollection>
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
