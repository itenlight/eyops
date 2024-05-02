xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace e555-lib="http://espa.gr/v6/e555/lib";

declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace error="urn:espa:v6:library:error";
declare namespace e524="http://espa.gr/v6/e524";

(: Namespaces e555 :)
declare namespace e555-db="http://xmlns.oracle.com/pcbpel/adapter/db/top/GetDeltioService";
(:: import schema at "ADAPTERS/E555GetDeltioService/GetDeltioService_table.xsd" ::)
declare namespace e555="http://espa.gr/v6/e555";


declare function e555-lib:if-empty( $arg as item()? ,$value as item()* )  as item()* {
  if (string($arg) != '') then 
    data($arg)
  else $value
 } ;
 
 declare function e555-lib:right-trim($arg as xs:string?) as xs:string {
   replace($arg,'\s+$','')
 } ;
 
 declare function e555-lib:get-lang($inbound as element()) as xs:string{
  fn:upper-case(fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2))
};

declare function e555-lib:get-user($inbound as element()) as xs:string{
 fn:upper-case(xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value))
};

declare function e555-lib:GetTrasmittionList($TraAA as xs:unsignedInt, $IDEp as xs:unsignedShort) as element(){

 let $TransmittionList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('TRANSMITTION-LIST'),
                                           'select distinct tra_aa, etos, list_values.anafora_eos, list_values.ypovolh_eos
                                            from KPS6_EP_PROGRAMMATA_EKD epekd, KPS6_DELTIO_TRANSMISSION dt,
                                                 (select a.kathg_group_ep, a.anafora_period , b.list_value_name anafora_eos, c.list_value_name ypovolh_eos
                                                  from KPS6_TRANSMISSION_PERIODS a, kps6_list_categories_values b, kps6_list_categories_values c
                                                  where a.anafora_period = b.list_value_id
                                                    and a.ypovolh_sfc = c.list_value_id
                                                    and b.list_category_id = 505
                                                    and c.list_category_id = 509
                                                 ) list_values
                                            where epekd.id_ep = dt.id_ep
                                              and list_values.kathg_group_ep = dt.kathg_group_ep
                                              and list_values.anafora_period = dt.anafora_period
                                              and nvl(?, dt.id_ep) = dt.id_ep
                                              and epekd.FLAG_ISXYS = 1
                                              and nvl(?, tra_aa) = tra_aa', $IDEp, $TraAA)
 
 return
  <E555Response xmlns='http://espa.gr/v6/e555'>
   {if ($TransmittionList/node()) then
     for $Row in $TransmittionList return
     <Row>
      <traAa>{xs:unsignedInt($Row//*:TRA_AA)}</traAa>
      <etos>{fn:data($Row//*:ETOS)}</etos>
      <anaforaEos>{fn:data($Row//*:ANAFORA_EOS)}</anaforaEos>
      <ypovolhEos>{fn:data($Row//*:YPOVOLH_EOS)}</ypovolhEos>
     </Row>
    else <Row/>
   }
  </E555Response>
};

declare function e555-lib:GetPeriodosAnaforasList() as element(){
  let $PeriodosAnaforasList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('TRANSMITTION-LIST'),
                                           'select distinct b.list_value_kodikos_display, b.list_value_name anafora_eos, c.list_value_name ypovolh_eos 
                                            from KPS6_TRANSMISSION_PERIODS a, kps6_list_categories_values b, kps6_list_categories_values c
                                            where a.anafora_period = b.list_value_id
                                              and b.list_category_id = 505
                                              and c.list_category_id = 509
                                              and a.ypovolh_sfc = c.list_value_id
                                              and a.kathg_group_ep in (select   list_value_id_a 
                                                                       from KPS6_LIST_VALUES_SYSXETISMOI sys, KPS6_EP_PROGRAMMATA_EKD epekd 
                                                                       where  epekd.id_ep = list_value_id_b 
                                                                         and  SYSX_KATHG = 59430 and epekd.FLAG_ISXYS = 1)')
  return
  <E555Response xmlns='http://espa.gr/v6/e555'>
   {if ($PeriodosAnaforasList/node()) then
     for $Row in $PeriodosAnaforasList return
     <Row>
      <listValueKodikosDisplay>{fn:data($Row//*:LIST_VALUE_KODIKOS_DISPLAY)}</listValueKodikosDisplay>
      <anaforaEos>{fn:data($Row//*:ANAFORA_EOS)}</anaforaEos>
      <ypovolhEos>{fn:data($Row//*:YPOVOLH_EOS)}</ypovolhEos>
     </Row>
    else <Row/>
   }
  </E555Response>                                                                         
};
declare function e555-lib:GetEpList() as element(){
  let $EpList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('EP_PROGRAMMATA'),
                                           'select ep.id_ep, epekd.titlos 
                                              from KPS6_EP_PROGRAMMATA ep 
                                              inner join KPS6_EP_PROGRAMMATA_EKD epekd on epekd.ID_EP = ep.ID_EP  
                                              where epekd.FLAG_ISXYS = 1')
  return
  <E555Response xmlns='http://espa.gr/v6/e555'>
   {if ($EpList/node()) then
     for $Row in $EpList return
     <Row>
      <idEp>{fn:data($Row//*:ID_EP)}</idEp>
      <titlos>{fn:data($Row//*:TITLOS)}</titlos>
     </Row>
    else <Row/>
   }
  </E555Response>                                                                         
};

declare function e555-lib:GetSearchAnaforaPeriodList($idEp as xs:unsignedLong) as element(){
  let $EpList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('TRANSMISSION_PERIODS'),
                            'with main_script as
                              (select case when extract (month from to_date(list_value_kodikos_display, ''dd/mm'')) >= prohg_examhno.month_prohg then year_prohg
                                when extract (month from to_date(list_value_kodikos_display, ''dd/mm'')) <= next_trimhno.month_next then  year_next
                                else null end netos, b.list_value_id    nanafora_period ,
                                B.LIST_VALUE_NAME   anafora_period_descr,
                                kathg_group_ep
                              from KPS6_TRANSMISSION_PERIODS a, kps6_list_categories_values b,
                                  (select extract  (year from add_months(sysdate, -6)) year_prohg,  extract  (month from add_months(sysdate, -6)) month_prohg from dual) prohg_examhno,
                                  (select  extract  (year from add_months(sysdate, 3)) year_next,  extract  (month from add_months(sysdate, 3)) month_next from dual) next_trimhno
                                  where a.anafora_period = b.list_value_id
                                  and b.list_category_id = 505
                                  and a.kathg_group_ep in (select   list_value_id_a from KPS6_LIST_VALUES_SYSXETISMOI sys, KPS6_EP_PROGRAMMATA_EKD epekd where  epekd.id_ep = list_value_id_b and  SYSX_KATHG = 59430 and epekd.FLAG_ISXYS = 1 and sys.list_value_id_b = :idep)
                                  and (extract (month from to_date(list_value_kodikos_display, ''dd/mm'')) >= prohg_examhno.month_prohg
                                  or  extract (month from to_date(list_value_kodikos_display, ''dd/mm'')) <= next_trimhno.month_next))
                            select netos, nanafora_period, anafora_period_descr
                                  from main_script a
                                  where  not exists (select 1 from  KPS6_DELTIO_TRANSMISSION  dt where  a.kathg_group_ep = dt.kathg_group_ep  and  a.nanafora_period = dt.anafora_period and dt.etos = netos)
                                  order by 1', $idEp)
  return
  <E555Response xmlns='http://espa.gr/v6/e555'>
   {if ($EpList/node()) then
     for $Row in $EpList return
     <Row>
      <etos>{fn:data($Row//*:NETOS)}</etos>
      <anaforaPeriod>{fn:data($Row//*:NANAFORA_PERIOD)}</anaforaPeriod>
      <anaforaPeriodDescr>{fn:data($Row//*:ANAFORA_PERIOD_DESCR)}</anaforaPeriodDescr>
     </Row>
    else <Row/>
   }
  </E555Response>                                                                         
};
declare function e555-lib:GetSearchTableList($idTra as xs:unsignedLong) as element(){
  let $TraList := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('TRANSMISSION_PERIODS'),
                                'select b.table_required
                            from KPS6_TRANSMISSION_PERIODS a, KPS6_TRANSMISSION_TABLES b, KPS6_DELTIO_TRANSMISSION c
                            where a.id_trper = b.id_trper
                            and a.kathg_group_ep = c.kathg_group_ep 
                            and a.anafora_period = c.anafora_period   
                            and c.id_tra =?', $idTra)
  return
  <E555Response xmlns='http://espa.gr/v6/e555'>
   {if ($TraList/node()) then
     for $Row in $TraList return
     <Row>
      <tableRequired>{fn:data($Row//*:TABLE_REQUIRED)}</tableRequired>
     </Row>
    else <Row/>
   }
  </E555Response>
};
declare function  e555-lib:map-db-to-get-response($inbound as element(), $db-response as element(), $idTra as xs:string) 
as element(){
 <E555Response xmlns='http://espa.gr/v6/e555'>
    <ERROR_CODE/>
    <ERROR_MESSAGE/>
    <DATA>
    {if ($db-response//e555-db:Kps6DeltioTransmission/node()) then 
      <Kps6DeltioTransmission> 
        <idTra>{fn:data($idTra)}</idTra>
        <traEkdosh>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:traEkdosh)}</traEkdosh>
        <traAa>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:traAa)}</traAa>
        <idEp>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:idEp)}</idEp>
        <idEpekd>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:idEpekd)}</idEpekd>
        <etos>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:etos)}</etos>
        <anaforaPeriod>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:anaforaPeriod)}</anaforaPeriod>
        <kathgGroupEp>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:kathgGroupEp)}</kathgGroupEp>
        <keimeno>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:keimeno)}</keimeno>
        <sxoliaEyd>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:sxoliaEyd)}</sxoliaEyd>
        <sxoliaYops>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:sxoliaYops)}</sxoliaYops>
        <objStatusId>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:objStatusId)}</objStatusId>
        <objStatusDate>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:objStatusDate)}</objStatusDate>
        <objIsxys>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:objIsxys)}</objIsxys>
        <objIsxysDate>{fn:data($db-response//e555-db:Kps6DeltioTransmission/e555-db:objIsxysDate)}</objIsxysDate>
        {if ($db-response//e555-db:Kps6DeltioTransmission/e555-db:vs6DeltioTransmissionInfo/node()) then 
        <Vs6DeltioTransmission>
        <idTra>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:idTra)}</idTra>
        <idEp>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:idEp)}</idEp>
        <kodikosEp>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:kodikosEp)}</kodikosEp>
        <titlosEp>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:titlosEp)}</titlosEp>
        <titlosEpEn>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:titlosEpEn)}</titlosEpEn>
        <ekdoshEp>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:titlosEpEn)}</ekdoshEp>
        <armodiaDa>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:armodiaDa)}</armodiaDa>
        <dateEgkrishs>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:titlosEpEn)}</dateEgkrishs>
        <anaforaPeriod>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:anaforaPeriod)}</anaforaPeriod>
        <dedomenaEos>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:dedomenaEos)}</dedomenaEos>
        <ypovolhSfc>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:ypovolhSfc)}</ypovolhSfc>
        <apostolhSfcEos>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:apostolhSfcEos)}</apostolhSfcEos>
        <tameia>{fn:data($db-response//e555-db:Vs6DeltioTransmission/e555-db:tameia)}</tameia>
        <descrTam>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:descrTam)}</descrTam>
        <eidosDeltioyDescr>{fn:data($db-response//e555-db:vs6DeltioTransmissionInfo/e555-db:eidosDeltioyDescr)}</eidosDeltioyDescr>
        </Vs6DeltioTransmission>
        else <Vs6DeltioTransmission/>
        }
       {if ($db-response//e555-db:Kps6DeltioTransmission/e555-db:kps6DelTransmissionDeiktesCollection/node()) then 
       for $Deikths in $db-response//e555-db:Kps6DeltioTransmission/e555-db:kps6DelTransmissionDeiktesCollection/e555-db:Kps6DelTransmissionDeiktes return
        <Kps6DelTransmissionDeiktes>
        <idTrdeik>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:idTrdeik)}</idTrdeik>
        <idTra>{fn:data($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="idTra"]/@value)}</idTra>
        <idEp>{fn:data($Deikths/e555-db:idEp)}</idEp>
        <idAxona>{fn:data($Deikths/e555-db:idAxona)}</idAxona>
        <idSo>{fn:data($Deikths/e555-db:idSo)}</idSo>
        <idTam>{fn:data($Deikths/e555-db:idTam)}</idTam>
        <idKatper>{fn:data($Deikths/e555-db:idKatper)}</idKatper>
        <idAtp>{fn:data($Deikths/e555-db:idAtp)}</idAtp>
        <idDeikth>{fn:data($Deikths/e555-db:idDeikth)}</idDeikth>
        <idEidd>{fn:data($Deikths/e555-db:idEidd)}</idEidd>
        <idMm>{fn:data($Deikths/e555-db:idMm)}</idMm>
        <timhStoxos>{fn:data($Deikths/e555-db:timhStoxos)}</timhStoxos>
        <timhOroshmo>{fn:data($Deikths/e555-db:timhOroshmo)}</timhOroshmo>
        <timhBashs>{fn:data($Deikths/e555-db:timhBashs)}</timhBashs>
        <timhStoxosMis>{fn:data($Deikths/e555-db:timhStoxosMis)}</timhStoxosMis>
        <timhYlopMisFixed>{fn:data($Deikths/e555-db:timhYlopMisFixed)}</timhYlopMisFixed>
        <timhYlopMis>{fn:data($Deikths/e555-db:timhYlopMis)}</timhYlopMis>
        <timhYlopMenFixed>{fn:data($Deikths/e555-db:timhYlopMenFixed)}</timhYlopMenFixed>
        <timhYlopMen>{fn:data($Deikths/e555-db:timhYlopMen)}</timhYlopMen>
        <timhYlopWomenFixed>{fn:data($Deikths/e555-db:timhYlopWomenFixed)}</timhYlopWomenFixed>
        <timhYlopWomen>{fn:data($Deikths/e555-db:timhYlopWomen)}</timhYlopWomen>
        <aitiologia>{fn:data($Deikths/e555-db:aitiologia)}</aitiologia>
        <tableId>{fn:data($Deikths/e555-db:tableId)}</tableId>
        {if ($Deikths//e555-db:vs6DelTransDeiktesInfo/node()) then 
        <Vs6DelTransDeiktesInfo>
        <idTrdeik>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:idTrdeik)}</idTrdeik>
        <idEp>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:idEp)}</idEp>
        <kodikosAxona>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:kodikosAxona)}</kodikosAxona>
        <descrTam>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:descrTam)}</descrTam>
        <descrTamEn>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:descrTamEn)}</descrTamEn>
        <descrKatper>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:descrKatper)}</descrKatper>
        <descrKatperEn>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:descrKatperEn)}</descrKatperEn>
        <kodikosDeikth>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:kodikosDeikth)}</kodikosDeikth>
        <idAtp>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:idAtp)}</idAtp>
        <perigrafh>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:perigrafh)}</perigrafh>
        <perigrafhEn>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:perigrafhEn)}</perigrafhEn>
        <syntm>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:syntm)}</syntm>
        <analogiaYlopoihshs>{fn:data($Deikths/e555-db:vs6DelTransDeiktesInfo/e555-db:analogiaYlopoihshs)}</analogiaYlopoihshs>
         </Vs6DelTransDeiktesInfo>                                   
         else <Vs6DelTransDeiktesInfo/>
         }                                         
      </Kps6DelTransmissionDeiktes>
      else <Kps6DelTransmissionDeiktes/>
      }
      </Kps6DeltioTransmission>
      else <Kps6DeltioTransmission/>
      }
      </DATA>
      {if ($db-response//e555-db:Kps6DeltioTransmission/node()) then 
      (<actionCode/>,
        <comments/>,
        <combineChecks>1</combineChecks>)   
       else ()}
 </E555Response>
};