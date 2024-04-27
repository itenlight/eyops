xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace e555-lib="http://espa.gr/v6/e555/lib";

declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace error="urn:espa:v6:library:error";
declare namespace e524="http://espa.gr/v6/e524";


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

