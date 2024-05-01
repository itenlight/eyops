xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace docs-lib="urn:espa:v6:library:documents";

(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";

declare function docs-lib:if-absent($arg as item()*,$Value as item()*) as item()* {
    if (exists($arg))
    then $arg
    else $Value
} ;

declare function docs-lib:replace-invalid-chars($arg as xs:string?, $ChangeFrom as xs:string*,$ChangeTo as xs:string* ) as xs:string? {

   if (count($ChangeFrom) > 0)
   then docs-lib:replace-invalid-chars(
          replace($arg, $ChangeFrom[1], docs-lib:if-absent($ChangeTo[1],'')),
                  $ChangeFrom[position() > 1],
                  $ChangeTo[position() > 1])
   else $arg
 } ;
 
 (: function that takes a sequence of elements and updates their values with the values specified in $value :)
 declare function docs-lib:replace-element-values($elements as element()*, $values as xs:anyAtomicType*) as element()* {
   for $element at $seq in $elements
   return element { node-name($element)}
             { $element/@*,
               $values[$seq] }
 } ;

(:replace a node with a new value:)
declare function docs-lib:replace-node($input-xml as node(), $xpath as xs:string, $replacement as node()) as node() {
  typeswitch ($input-xml)
    case element() return
      if ($input-xml[self::node()[matches(name(), $xpath)]]) then
        $replacement
      else
        element { node-name($input-xml) } {
          $input-xml/@*,
          for $child in $input-xml/node()
            return docs-lib:replace-node($child, $xpath, $replacement)
        }
    default return $input-xml
};
 

declare function docs-lib:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function docs-lib:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};

declare function docs-lib:GetUserCategory($User as xs:string) as xs:unsignedByte{
  xs:unsignedByte(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                      'Select RLS7_Security.GetSSOUserKathg(?) Katigoria From Dual',
                                      $User)//*:KATIGORIA)
};

declare function docs-lib:GetKatastasiDeltiou($BulletinID as xs:unsignedInt, $BulletinCategory as xs:unsignedByte) as xs:unsignedShort{
  xs:unsignedShort(if ($BulletinCategory = (5,21,22,26)) then 302 
                       else fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                          'Select Kps6_Core.Get_Obj_Status(?, ?) Status 
                                           From Dual',
                                           $BulletinID, $BulletinCategory)//*:STATUS)
};

declare function docs-lib:FetchAttachments($Document as element(), $User as xs:string) {
  fn:false()
};


declare function docs-lib:AllowedActions($AttachedDocument as element(), $User as xs:string) as element(){

  let $UserCategory := docs-lib:GetUserCategory($User) 
  
  return
    $AttachedDocument
};


declare function docs-lib:HasUserInsertRight($BulletinID as xs:unsignedInt, $BulletinCategory as xs:unsignedByte, $User as xs:string) as xs:boolean {
 
 let $UserCategory := docs-lib:GetUserCategory($User) 
 let $KatastasiDeltiou := docs-lib:GetKatastasiDeltiou($BulletinID,$BulletinCategory)
 return
  if ($KatastasiDeltiou = (302,303,304,305,307,308,309)) then 
   if ($UserCategory=2) then fn:true() else fn:false()
  else if ($KatastasiDeltiou = (300,306)) then 
   if ($UserCategory=1) then fn:true() else fn:false() 
  else fn:false()
};

declare function docs-lib:CategoriesList($DocumentTypeID as xs:unsignedShort, $Lang as xs:string) as element(){
  let $Query := fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('SQL-RESULT'),
                                           'Select A.List_Value_ID As ID, 
                                            Case When Upper(?) = ''GR'' 
                                               Then A.List_Value_Name  
                                               Else A.List_Value_Name_En 
                                            End As Description 
                                            From Kps6_List_Categories_Values A, Kps6_Egrafa_Deltioy B
                                            Where A.List_Category_ID = 510
                                              And A.List_Value_ID = B.Kodikos_Egrafoy
                                              And B.Object_Category_ID = ?
                                              And List_Value_ID Not In (51950, 51538)
                                            Order By A.List_Value_AA', $Lang, $DocumentTypeID)
  return                                            
  <AttachmentResponse xmlns="urn:espa:v6:documents">
   {if($Query/node()) then
    for $Row in $Query return
      <Row>
        <id>{fn:data($Row//*:ID)}</id>
        <description>{fn:data($Row//*:DESCRIPTION)}</description>
      </Row>
    else 
    <Row/>
   }
  </AttachmentResponse>
};

declare function docs-lib:GetTopopoihsiList($Lang as xs:string) as element(){
  let $Query := fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('SQL-RESULT'),
                                           'Select A.List_Value_ID As ID, 
                                                   Case When Upper(?) = ''GR'' 
                                                    Then A.List_Value_Name  
                                                    Else A.List_Value_Name_En 
                                                   End As Description
                                            From Kps6_List_Categories_Values A
                                            Where A.List_Category_ID = 563
                                              And A.Is_Active=1
                                            Order By A.List_Value_AA', $Lang)
  return                                                                                       
  <AttachmentResponse xmlns="urn:espa:v6:documents">
   {if($Query/node()) then
    for $Row in $Query return
      <Row>
        <id>{fn:data($Row//*:ID)}</id>
        <description>{fn:data($Row//*:DESCRIPTION)}</description>
      </Row>
    else 
    <Row/>
   }
  </AttachmentResponse>
};

declare function docs-lib:MaxSizeAllowed() as xs:unsignedLong{

  xs:unsignedLong(fn-bea:execute-sql('jdbc/mis_master6DS', xs:QName('SQL-RESUTL'),
                     'Select Extra_Val
                      From C6_Parameters
                      Where Kodikos = 102
                        And Extra_Val Is Not Null')//*:EXTRA_VAL)
};

declare function docs-lib:RetrieveDocumentAttachemts($BulletinID as xs:unsignedInt, 
                                                     $BulletinCategory as xs:unsignedByte, 
                                                     $Overview as xs:boolean,
                                                     $FetchAll as xs:boolean,
                                                     $User as xs:string,
                                                     $Lang as xs:string) as element(){
  let $InvalidChars := ('\', '<', '>', "'", '!', '=', '^', '~', 'α', 'β', 'γ', 'δ', 'ε', 'ζ', 'η', 'θ', 'ι', 'κ', 'λ', 'μ', 'ν', 'ξ', 'ο', 'π', 'ρ', 'σ', 'τ', 'υ', 'φ', 'χ', 'ψ', 'ω', 'έ', 'ό', 'ά', 'ί', 'ή', 'ώ', 'ϋ', 'ύ', 'ϊ', 'Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ', 'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω', 'Ά', 'Έ', 'Ή', 'Ί', 'Ό', 'Ύ', 'Ώ', 'ς', '%', '@', '#', '$', '`', ',', ')', '|', '+', '\t')
  let $ValidChars := ('','','','','','','','','a', 'v', 'g', 'd', 'e', 'z', 'i', 'th', 'i', 'k', 'l', 'm', 'n', 'x', 'o', 'p', 'r', 's', 't', 'y', 'f', 'ch', 'ps', 'o', 'e', 'o', 'a', 'i', 'i', 'o', 'y', 'y', 'i', 'A', 'V', 'G', 'D', 'E', 'Z', 'I', 'TH', 'I', 'K', 'L', 'M', 'N', 'X', 'O', 'P', 'R', 'S', 'T', 'Y', 'F', 'CH', 'PS', 'O', 'A', 'E', 'I', 'I', 'O', 'Y','O' ,'s' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'' ,'')
  let $UserCategory := docs-lib:GetUserCategory($User) 
  let $KatastasiDeltiou := docs-lib:GetKatastasiDeltiou($BulletinID,$BulletinCategory)
  let $Query := 'Select Distinct Doc.ID_Document, Doc.ID_Object, Doc.Object_Category_ID, Doc.Doc_Num, 
                        Doc.Doc_Filename, Doc.Doc_Descr,
                        Case When Upper(?) = ''GR'' 
                             Then Cat.List_Value_Name 
                             Else Cat.List_Value_Name_En 
                        End As Doc_Cat_Desc, 
                        Doc.Doc_Foreas, Doc.Doc_Syntakths, Doc.Doc_Sxolia, Doc.Doc_Date_Eggrafoy,
                        Doc.Doc_Lang, Doc.Doc_Source, Doc.Doc_Eidos_Eggrafoy, Doc.Doc_Egkyro,Doc.Doc_Fakelos_Flag,
                        Doc.Flag_Epd,Doc.Flag_Encryption,Doc.ID_Object_Proeleysh,Doc.Object_Cat_Proeleysh, 
                        Doc.Dilosi, Doc.Eidos_Taytopoihshs, Doc.Kodikos_Systhmatos_Ext, Doc.Typos_Arxeioy, 
                        Doc.Doc_Anaptyxi
                From  Com6_Doc_Metadata Doc, Kps6_List_Categories_Values Cat
                Where  Doc.ID_Object = ?
                  And Doc.Object_Category_ID = ?
                  And Doc.Doc_Eidos_Eggrafoy = Cat.List_Value_ID
                  And Cat.List_Category_ID = ?'
  let $FakeStatus := fn:false()

  return
  <AttachmentResponse>
  {for $Row in fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESUTL'),
                                  if($UserCategory=1) then fn:concat($Query,' And Doc.Doc_Source In (''1'',''2'',''5'',
                                                                            ''6'',''7'',''8'',''9'') 
                                                                            And Doc.Doc_Egkyro !=0') else $Query,
                                  $BulletinID, $BulletinCategory)
      let $ProeleusiArxeiou := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                               'Select Case 
                                                        When Upper(:pLang) = ''GR'' Then K.List_Value_Name 
                                                        Else K.List_Value_Name_En 
                                                      End as Value_Name
                                                From Master6.Kps6_List_Categories_Values K 
                                                Where List_Category_ID = 519 
                                                  And List_Value_Aa = ?
                                                  And RowNum =1',xs:string($Row//*:DOC_SOURCE))
   return
    if($Row/node()) then
    <Row>
      <attachmentDocumentId>{fn:data($Row//*:ID_DOCUMENT)}</attachmentDocumentId>
      <attachmentSize>
        {if(Row//*:DOC_FILENAME/text()) then 
           let $DocSize := fn-bea:execute-sql('jdbc/mis_filesDSNonXA',xs:QName('SQL-RESULT'),
                                     'Select Round(Check6_Doc_Size(ID_Document)/1048576, 3) DocSize 
                                      From Com6_Documents  
                                      Where ID_Document = ? 
                                        And RowNum=1', xs:unsignedLong($Row//*:ID_DOCUMENT))//*:DOCSIZE  
           return
            if ($DocSize/text()) then xs:unsignedLong($DocSize) else 0            
         else ()
        }
      </attachmentSize>
      <deleteModeOptionAvailable>{fn:data($Row//*:DOC_SOURCE)}</deleteModeOptionAvailable>
      <description>{fn:data($Row//*:DOC_DESCR)}</description>
      <dilosi>{fn:data($Row//*:DILOSI)}</dilosi>
      <docAnaptyxi>{fn:data($Row//*:DOC_ANAPTYXI)}</docAnaptyxi>
      <docEgkyro>{fn:data($Row//*:DOC_EGKYRO)}</docEgkyro>
      <docFakelosFlag>{fn:data($Row//*:DOC_FAKELOS_FLAG)}</docFakelosFlag>
      <docFileName>{fn:data($Row//*:DOC_FILENAME)}</docFileName>
      <docLang>{fn:data($Row//*:DOC_LANG)}</docLang>
      <docNum>{fn:data($Row//*:DOC_NUM)}</docNum>
      <docProeleusiArxeiou>
       {if (fn:not(fn:data($Row//*:DOC_SOURCE)=(2,3,5,6,7,8))) then '-'
        else fn:data($ProeleusiArxeiou//*:VALUE_NAME)
       }
      </docProeleusiArxeiou>
      <docSource>{fn:data($Row//*:DOC_SOURCE)}</docSource>
      <document>
        <deltioId>{$BulletinID}</deltioId>
        <deltioTypeId>{$BulletinCategory}</deltioTypeId>
        <overviewDocument>{$Overview}</overviewDocument>
      </document>
      <documentCategory>
        <aa></aa>
        <description>{fn:data($Row//*:DOC_CAT_DESC)}</description>
        <id>{fn:data($Row//*:DOC_EIDOS_EGGRAFOY)}</id>
      </documentCategory>
      <documentProeleysh>
        <description></description>
        <id></id>
      </documentProeleysh>
      <downloadOptionAvailable>{fn:data($Row//*:DOC_DESCR)}</downloadOptionAvailable>
      <editModeOptionAvailable>{fn:data($Row//*:DOC_DESCR)}</editModeOptionAvailable>
      <eidosTaytopoihshs>{fn:data($Row//*:EIDOS_TAYTOPOIHSHS)}</eidosTaytopoihshs>
      <flagEncryption>{fn:data($Row//*:FLAG_ENCRYPTION)}</flagEncryption>
      <flagEpd>{fn:data($Row//*:FLAG_EPD)}</flagEpd>
      <foreasDikaioyxoy>{fn:data($Row//*:DOC_FOREAS)}</foreasDikaioyxoy>
      <hmeromEggrafoy>{fn:data($Row//*:DOC_DATE_EGGRAFOY)}</hmeromEggrafoy>
      <idObjectProeleysh>{fn:data($Row//*:ID_OBJECT_PROELEYSH)}</idObjectProeleysh>
      {let $LogUserAction := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
                                  'Select L.Log_User_Action_ID, L.Action_Category_ID, L.User_Name,
                                          (Select Max (Date_Action)
                                           From Kps6_Log_User_Actions
                                           Where Kps6_Log_User_Actions.Object_Category_ID = 20
                                             And Kps6_Log_User_Actions.Object_ID = C.ID_Document) As Date_Last_Update,
                                          L.Object_Category_ID, L.Object_ID, L.Comments_Action, L.Date_Action As Ins_Date
                                   From Kps6_Log_User_Actions L, Com6_Doc_Metadata C
                                   Where L.Object_ID = C.ID_Document
                                     And L.Object_Category_ID = 20
                                     And L.Action_Category_ID = 1
                                     And C.ID_Document = ?',xs:unsignedLong($Row//*:ID_DOCUMENT))
       return
       (
        <insertDate>{fn:data($LogUserAction//*:INS_DATE)}</insertDate>,
        <insertUser>{fn:data($LogUserAction//*:USER_NAME)}</insertUser>
        )
      } 
      <kodikosSysthmatosExt>{fn:data($Row//*:KODIKOS_SYSTHMATOS_EXT)}</kodikosSysthmatosExt>
      <objectCatProeleysh>{fn:data($Row//*:OBJECT_CAT_PROELEYSH)}</objectCatProeleysh>
      <relatedFile>{fn:data($Row//*:DOC_DESCR)}</relatedFile>
      <sxolia>{fn:data($Row//*:DOC_SXOLIA)}</sxolia>
      <syntakths>{fn:data($Row//*:DOC_SYNTAKTHS)}</syntakths>
      <typosArxeioy>{fn:data($Row//*:TYPOS_ARXEIOY)}</typosArxeioy>
      <updateDate/>      
      {if ($KatastasiDeltiou = (301,303,330)) then
        if($UserCategory = 2 and fn:data($Row//*:DOC_SOURCE) = (1,2,6,7,8)) then
          (if (fn:data($Row//*:DOC_SOURCE)= (2,8)) then
             <isDeleteModeOptionAvailable>{fn:true()}</isDeleteModeOptionAvailable>
           else <isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:true()}</isUpdateMetadataOptionAvailable>,
           if (fn:data($Row//*:DOC_SOURCE)= (2,8) and 
               fn:not(fn:data($Row//*:ID_OBJECT_PROELEYSH)) and 
               fn:not(fn:data($Row//*:OBJECT_CAT_PROELEYSH))) then 
            <isUploadNewFileOptionAvailable>{fn:true()}</isUploadNewFileOptionAvailable>
           else <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>)
        else
          (<isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:false()}</isUpdateMetadataOptionAvailable>,
           <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>,
           <updateMetadataOptionAvailable>{fn:false()}</updateMetadataOptionAvailable>)
      else if ($KatastasiDeltiou = (304,307,305,308,309)) then
        if($UserCategory = 2 and fn:data($Row//*:DOC_SOURCE) = (1,2,6,7)) then
          (<isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:false()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:false()}</isUpdateMetadataOptionAvailable>,
           <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>)           
        else
          (<isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:false()}</isUpdateMetadataOptionAvailable>,
           <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>)
      else if ($KatastasiDeltiou = 301) then
           (<isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:false()}</isUpdateMetadataOptionAvailable>,
           <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>)
      else if ($KatastasiDeltiou = (300, 302, 306)) then 
        if(($UserCategory = 1 and fn:data($Row//*:DOC_SOURCE) = 1) or $KatastasiDeltiou = 302) then
           (<isDeleteModeOptionAvailable>{fn:true()}</isDeleteModeOptionAvailable>,
            <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
            <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
            <isUpdateMetadataOptionAvailable>{fn:true()}</isUpdateMetadataOptionAvailable>,
            <isUploadNewFileOptionAvailable>{fn:true()}</isUploadNewFileOptionAvailable>)
        else
          (<isDeleteModeOptionAvailable>{fn:false()}</isDeleteModeOptionAvailable>,
           <isDownloadOptionAvailable>{fn:true()}</isDownloadOptionAvailable>,
           <isEditModeOptionAvailable>{fn:true()}</isEditModeOptionAvailable>,
           <isUpdateMetadataOptionAvailable>{fn:false()}</isUpdateMetadataOptionAvailable>,
           <isUploadNewFileOptionAvailable>{fn:false()}</isUploadNewFileOptionAvailable>)
     else ()       
      }  
    </Row>    
    else <Row/>                                  
  }
  </AttachmentResponse>
};

(: Set actions on attachment allowed by user :)
declare function docs-lib:SetAttachmentAllowedActions($Attachment as element(), $User as xs:string) as element(){
 let $UserCategory := docs-lib:GetUserCategory($User)  
 
 return
  <A></A>
   
  
};


(: Remove an Attachement with it's Metadata :)
declare function docs-lib:Remove($DocumentAttachment as element(), $File as element()) {

''
};


(: Persist an Attachement with it's Metadata :)
declare function docs-lib:Persist($DocumentAttachment as element(), $File as element()) {

''
};
