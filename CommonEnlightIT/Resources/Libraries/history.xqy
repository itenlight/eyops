xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace history="urn:espa:v6:library:history";


(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";

declare function history:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function history:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};


declare function history:GetDeltioHistoryChanges($ObjectID as xs:unsignedInt, $ObjectCategoryID as xs:unsignedShort, $Lang as xs:string) as element(){
 <HistoryResponse xmlns="urn:espa:v6:history">
 {let $HistoryList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('History-List'),
        "WITH
          Constants As
             (Select To_Number(?) As ObjectID, To_Number(?) As ObjectCategoryID From Dual),
          History As
              (Select U.Object_Category_ID,
                      OBJ.Object_Category_Name,
                      U.Status_Update_ID,
                      U.Object_ID,
                      U.Object_Status_ID,
                      Case
                          When U.Object_Category_ID = 182 And U.Object_Status_ID = 304
                            Then
                               (Select Case When  Upper(?)='GR' Then 'Υποβληθέν' Else 'Submitted' End As Object_Status_Name
                                From Kps6_Enl_Aithma
                                Where ID_Enlait = U.Object_ID
                                 And Kps6_Enl_Aithma.DHMIOYRGOS = 321
                                Union
                                Select s2.Object_Status_Name
                                From Kps6_Enl_Aithma
                                Where ID_Enlait = U.Object_ID
                                 And Kps6_Enl_Aithma.DHMIOYRGOS != 321)
                            Else
                               Case When Upper(?)='GR' Then S2.Object_Status_Name Else S2.Object_Status_Name_En End 
                         End As Object_Status_Name,                         
                         Case When Upper(?) = 'GR' Then U.Comments_Status 
                              Else Replace (Replace (Replace (U.Comments_Status,
                                        'Δημιουργήθηκε νέα Πρόσκληση (ή νέα Έκδοση) με Α/Α:',
                                        'A new Call hAs been created. Call code:'),
                                        'Δημιουργήθηκε νέο Τ.Δ.Π. με  Α/Α: ',
                                        'A New Record HAs Been Created: '),
                                        'Δημιουργήθηκε νέα Απόφαση με Α/Α: ',
                                        'A new Resolution hAs been created. Resolution code:')
                         End As Comments_Status,
                         L.User_Name,
                         L.Date_Action,
                         U.Date_Update_Status,
                         SM.Recipient,
                         l.Log_User_Action_ID
                    From Kps6_Status_Updates U,
                         Kps6_Object_Category_Status S2,
                         Kps6_Log_User_Actions L,
                         Kps6_SendMail SM,
                         Kps6_Object_Categories OBJ
                   Where U.Object_Status_ID = S2.Object_Status_ID
                         And U.Object_Category_ID = S2.Object_Category_ID
                         And L.Log_User_Action_ID = U.Log_User_Action_ID
                         And U.Status_Update_ID = SM.Status_Update_ID(+)
                         And u.Object_Category_ID = OBJ.Object_Category_ID)
          Select Object_ID As ID_Deltioy,
                 Object_Category_ID,
                 Object_Category_Name,
                 Status_Update_ID,
                 Date_Action As System_Status_Date,
                 Object_Status_Name Status_Name,
                 User_Name As User_Name,
                 Case
                    When (Object_Status_ID = 301 And Object_Category_ID = 101)
                    Then
                       Case
                          When NVL (Date_Update_Status, To_Date ('010101', 'DDMMRRRR')) !=
                                  To_Date ('010101', 'DDMMRRRR')
                               And (TRUNC (Date_Action) <=
                                       To_Date ('31/03/2018', 'dd/mm/rrrr'))
                          Then
                              '(Παραλαβή Αίτησης/Τεχνικού Δελτίου Πράξης από ΔΑ)'
                          Else Comments_Status
                       End
                    Else
                       NVL (Comments_Status, '---')
                 End Comments_Status,
                 NVL (Recipient, '---') As Email_Recipients,
                 Log_User_Action_ID,
                 Object_Status_ID
          From History, Constants
          Where (History.Object_ID, History.Object_Category_ID) IN
                (Select Constants.ObjectID, Constants.ObjectCategoryID From Constants
                 Union
                 Select Epikoinonia_ID, 25
                 From Kps6_Epikoinonia E, Constants
                 Where Constants.ObjectID = E.Object_ID
                   And Constants.ObjectCategoryID = E.Object_Category_ID
                 Union
                 Select E.Eishghsh_ID, 24
                 From Kps6_Eishghsh E, Constants
                 Where Constants.ObjectID = E.Object_ID
                   And Constants.ObjectCategoryID = E.Object_Category_ID)
          Union
          Select LOGG.Object_ID As ID_Deltioy,
                 LOGG.Object_Category_ID,
                 (select OBJ.Object_Category_Name from Kps6_Object_Categories OBJ 
                  where logg.Object_Category_ID = OBJ.Object_Category_ID ) As Object_Category_Name,
                 Null As Status_Update_ID,
                 Date_Action As System_Status_Date,
                 Case When Upper(?)= 'GR' Then'Παρακολούθηση' Else 'Monitoring' End As Status_Name,
                 User_Name As User_Name,                 
                 Null As Comments_Status,
                 '---' As Email_Recipients,
                 LOGG.Log_User_Action_ID,
                 Null as Object_Status_ID
          From Kps6_Log_User_Actions LOGG, Constants
          Where LOGG.Object_ID = Constants.ObjectID
            And LOGG.Object_Category_ID = Constants.ObjectCategoryID
            And LOGG.Action_Category_ID = 17
          Order BY System_Status_Date Desc, Log_User_Action_ID Desc",
        $ObjectID, $ObjectCategoryID, $Lang, $Lang, $Lang, $Lang)
  return          
   if($HistoryList/node()) then 
    for $Entry in $HistoryList return
    <Entry>
     <logUserActionID>{fn:data($Entry//*:LOG_USER_ACTION_ID)}</logUserActionID>
     <statusUpdateID>{fn:data($Entry//*:STATUS_UPDATE_ID)}</statusUpdateID>
     <idDeltioy>{fn:data($Entry//*:ID_DELTIOY)}</idDeltioy>
     <statusDate>{fn:data($Entry//*:SYSTEM_STATUS_DATE)}</statusDate>
     <statusName>{fn:data($Entry//*:STATUS_NAME)}</statusName>
     <userName>{fn:data($Entry//*:USER_NAME)}</userName>
     <commentsStatus>{fn:data($Entry//*:COMMENTS_STATUS)}</commentsStatus>
     <emailRecipients>{fn:data($Entry//*:EMAIL_RECIPIENTS)}</emailRecipients>
     <objectCategoryID>{fn:data($Entry//*:OBJECT_CATEGORY_ID)}</objectCategoryID>
     <objectCategoryName>{fn:data($Entry//*:OBJECT_CATEGORY_NAME)}</objectCategoryName>
    </Entry>
   else <Entry/>     
   }
 </HistoryResponse>
};

declare function history:GetAnakinoseis($IDDeltiou as xs:unsignedLong) as element(){
  <HistoryResponse xmlns="urn:espa:v6:history">
  { let $Anakinoseis :=  fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Anakinoseis-List'),
             'SELECT object_id, date_action, user_name, comments_action 
              FROM kps5_log_user_actions 
              WHERE object_category_id = 22 
                And object_id = ?
              ORDER BY 1, 2', $IDDeltiou)
    return
     if ($Anakinoseis/node()) then
     for $Anakinosi in $Anakinoseis return
       <Anakinosi>
        <objectId>{fn:data($Anakinosi//*:OBJECT_ID)}</objectId>
        <dateAction>{fn:data($Anakinosi//*:DATE_ACTION)}</dateAction>
        <userName>{fn:data($Anakinosi//*:USER_NAME)}</userName>
        <commentAction>{fn:data($Anakinosi//*:COMMENTS_ACTION)}</commentAction>
       </Anakinosi>
     else
       <Anakinosi/>
  }
  </HistoryResponse>  
};

declare function history:GetPraksisChanges($PraksisID as xs:unsignedLong,
                                           $CategoryID as xs:unsignedShort, 
                                           $Lang as xs:string) as element()
{
  <HistoryResponse xmlns="urn:espa:v6:history">
  {let $Changes :=  fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Anakinoseis-List'),
                        'Select STATUS_UPDATE_ID,  
                         Case When Upper(:pLang)= ''GR'' Then Object_Status_Name Else Object_Status_Name_En End STATUS_NAME, 
                         To_date(nvl(Date_Update_Status, DATE_ACTION),''dd/mm/rrrr'') as STATUS_DATE, 
                         User_Name as USER_NAME ,
                         Decode(DATE_UPDATE_STATUS,NULL, 
                                Comments_Status || '' (Ημ/νίες Συστήματος)'', 
                                Comments_Status) As COMMENTS_STATUS  
                         From (Select U.STATUS_UPDATE_ID, 
                                      u.Object_Category_ID, 
                                      u.Object_ID, 
                                      u.Object_Status_ID, 
                                      s2.Object_Status_Name, 
                                      s2.Object_Status_Name_En,  
                                      u.Date_Update_Status, L.DATE_ACTION, L.USER_NAME, U.COMMENTS_STATUS 
                               From Kps6_Status_Updates u, Kps6_Object_Category_Status s2, Kps6_Log_User_Actions l 
                               Where u.Object_Status_ID = s2.Object_Status_ID 
                                 And u.Object_Category_ID = s2.Object_Category_ID 
                                 And l.Log_User_Action_ID = u.Log_User_Action_ID 
                                 And u.Object_ID = ?  
                                 And u.Object_Category_ID = ? 
                                 order by u.Status_update_ID desc)',$Lang, $PraksisID, $CategoryID)
   return
   if ($Changes/node()) then
    for $Change in $Changes return
     <Change>      
      <statusName>{fn:data($Change//*:STATUS_NAME)}</statusName>
      <statusDate>{fn:data($Change//*:STATUS_DATE)}</statusDate>
      <userName>{fn:data($Change//*:USER_NAME)}</userName>
      <commentsStatus>{fn:data($Change//*:COMMENTS_STATUS)}</commentsStatus>
     </Change>
    else
     <Change/>
  }
  </HistoryResponse>
};
