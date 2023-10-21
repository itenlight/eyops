xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace tdy="http://espa.gr/v6/tdy/library";

declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace error="urn:espa:v6:library:error";

(: Namespaces ΤΔΥ :)
declare namespace tdy-db="http://xmlns.oracle.com/pcbpel/adapter/db/top/TDY_read";
(:: import schema at "ADAPTERS/TDYReadService/TDYReadService_table.xsd" ::)
declare namespace tdy-response="http://espa.gr/v6/tdy";
(:: import schema at "XSD/nxsd_getdy_response.xsd" ::)
declare namespace tdy-db-update="http://xmlns.oracle.com/pcbpel/adapter/db/top/TDYWriteService";
(:: import schema at "ADAPTERS/TDYWriteService/TDYWriteService_table.xsd" ::)


declare function tdy:if-empty( $arg as item()? ,$value as item()* )  as item()* {
  if (string($arg) != '') then 
    data($arg)
  else $value
 } ;

declare function tdy:get-lang($inbound as element()) as xs:string{
  fn:substring(
    fn:tokenize($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='Cookie']/@value,'lang=')[2],
    1,2)
};

declare function tdy:get-user($inbound as element()) as xs:string{
 xs:string($inbound/ctx:transport/ctx:request/tp:headers/tp:user-header[@name='OAM_REMOTE_USER']/@value)
};

declare function tdy:GetVersionList($inbound as element()) as element(){
 <Versions xmlns="http://espa.gr/v6/tdy">
  {let $ListaVersion := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('VERSION'),
                'select b.tdy_id as id, b.AA_TDY||''.''||b.AA_YPOEKDOSH as ekdosh, 
                 decode(b.tdy_id,nvl(kps6_core.get_isxyon_deltio(b.kodikos_ypoergoy, 103, 304),0),''ΝΑΙ'',''-'')  se_isxys  
                 from kps6_ypoerga a, kps6_ypoerga b 
                 where a.kodikos_ypoergoy = b.kodikos_ypoergoy 
                   and a.tdy_id=? and b.tdy_id !=a.tdy_id',
                 xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="id"]/@value))
  return  
   if (fn:not($ListaVersion/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   else for $Version in $ListaVersion return
   <Version>
    <id>{fn:data($Version//*:ID)}</id>
    <ekdosh>{fn:data($Version//*:EKDOSH)}</ekdosh>
    <seIsxys>{fn:data($Version//*:SE_ISXYS)}</seIsxys>
   </Version>
  }
 </Versions>
};

declare function tdy:GetAaYpoergouList($inbound as element()) as element()*{
 
 let $ListaYpoergon:= fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('YPOERGO'),
                     'SELECT
                      TY.KODIKOS_MIS,
                      TY.aa_ypoergoy,
                      TY.TITLOS_YPOERGOY,
                      TY.KODIKOS_YPOERGOY,
                      TDY_YPOERGA.tdy_id,
                      nvl(tdy_ypoerga.TYPE_NEW_EKD, 5661) type_new_ek,
                      nvl(TDY_YPOERGA.new_ekdosh, 1) || ''.'' || nvl(TDY_YPOERGA.new_ypoekdosh, 0) nea_ekdosh,
                      nvl(TDY_YPOERGA.action_type, 5661) action_typ
                      FROM (WITH ekd AS (SELECT
                      a.KODIKOS_ypoergoy,
                      max_ekdosh,
                      max(b.aa_YPOEKDOSH) max_ypoekdosh,
                      egkek,
                      nvl((SELECT count(tdy_id)
                      FROM kps6_ypoerga
                      WHERE kodikos_ypoergoy = a.kodikos_ypoergoy AND
                      kps6_core.get_obj_status(tdy_id, 103) IN (300, 301, 302, 306)), 0) count_ekremeis_tot,
                      nvl((SELECT count(tdy_id)
                      FROM kps6_ypoerga
                      WHERE kodikos_ypoergoy = a.kodikos_ypoergoy AND
                      kps6_core.get_obj_status(tdy_id, 103) IN (300, 306)), 0) count_ekremeis_dik,
                      nvl((SELECT count(tdy_id)
                      FROM kps6_ypoerga
                      WHERE kodikos_ypoergoy = a.kodikos_ypoergoy AND
                      kps6_core.get_obj_status(tdy_id, 103) IN (301, 302)), 0)  count_ekremeis_da,
                      (SELECT A.FOREAS_KATHG
                      FROM MASTER6.APPL6_USERS A
                      WHERE UPPER(SSO_USER_NAME) = UPPER(?)) AS  USER_KAT
                      FROM (SELECT KODIKOS_ypoergoy, max(aa_tdy) max_ekdosh, 
                      DECODE(kps6_core.get_isxyon_deltio(kodikos_ypoergoy, 103, 304), -1, 0, 1) egkek
                      FROM KPS6_ypoerga
                      WHERE kodikos_mis = ?
                      GROUP BY KODIKOS_ypoergoy) a, kps6_ypoerga b
                      WHERE a.KODIKOS_ypoergoy = b.KODIKOS_ypoergoy AND max_ekdosh = b.aa_tdy
                      GROUP BY a.KODIKOS_ypoergoy, max_ekdosh, egkek) SELECT
                      w.kodikos_mis,
                      q.KODIKOS_ypoergoy,
                      (SELECT aa_ypoergoy
                      FROM kps6_tdp_ypoerga
                      WHERE id_tdp =
                      kps6_core.get_trexon_deltio(w.kodikos_mis,
                      101) AND
                      kodikos_ypoergoy = q.KODIKOS_ypoergoy)  AS AA_YPOERGOY,
                      w.tdy_id,
                      w.aa_tdy || ''.'' || w.aa_ypoekdosh  AS ekdosh_ypoekdosh,
                      W.titlos_ypoergoy,
                      nvl(MASTER6.kps6_core.Get_Obj_Status(w.tdy_id, 103),300) AS KATASTASH,
                      MASTER6.kps6_core.get_obj_status_desc(w.tdy_id,103) AS "KATAST_DESC",
                      MASTER6.kps6_core.get_obj_status_desc_en( w.tdy_id,103)  AS KATAST_DESC_en,
                      CASE WHEN (SELECT kps6_core.get_isxyon_deltio( W.KODIKOS_ypoergoy, 103, 304) FROM dual) = W.tdy_id
                      THEN ''ΝΑΙ''
                      ELSE ''ΟΧΙ'' END  isxys,
                      CASE WHEN egkek = 1
                      THEN max_ekdosh + 1
                      ELSE max_ekdosh END new_ekdosh,
                      CASE WHEN egkek = 1
                      THEN 0
                      ELSE max_ypoekdosh +1 
                      END  new_ypoekdosh,
                      CASE WHEN egkek = 1
                      THEN 5662
                      ELSE 5661 END type_NEW_ekd,
                      max_ekdosh || ''.'' || max_ypoekdosh  max_ekd,
                      Count_ekremeis_tot,
                      count_ekremeis_DIK,
                      count_ekremeis_DA,
                      q.user_kat,
                      CASE WHEN count_ekremeis_tot = 0
                      THEN CASE egkek
                      WHEN 1
                      THEN 5662
                      ELSE 5661 END
                      ELSE CASE WHEN (
                      (count_ekremeis_DA = 0 AND q.USER_KAT = 2) OR (count_ekremeis_DIK = 0 AND q.USER_KAT = 1))
                      THEN 15662
                      ELSE -1 END END  ACTION_TYPE
                      FROM ekd q, kps6_ypoerga w
                      WHERE q.KODIKOS_ypoergoy = w.KODIKOS_ypoergoy AND
                      W.TDY_ID = (SELECT KPS6_CORE.GET_MAX_AA(w.KODIKOS_ypoergoy, 103) FROM DUAL)) TDY_YPOERGA,
                      kps6_tdp_ypoerga TY
                      WHERE TY.KODIKOS_YPOERGOY = TDY_YPOERGA.KODIKOS_YPOERGOY (+) AND
                      TY.id_tdp = kps6_core.get_trexon_deltio(TY.kodikos_mis, 101) AND ty.kodikos_mis =  ? 
                             and NVL (?, TY.AA_YPOERGOY) = TY.AA_YPOERGOY
                      ORDER BY 1, 2',
                      tdy:get-user($inbound),
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value),
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value),
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="aaYpoergou"]/@value))
   return 
   <ListYpoergon xmlns="http://espa.gr/v6/tdy">
   {
    if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
    for $Ypoergo in $ListaYpoergon return
    <Ypoergo>
      <kodikosMis>{fn:data($Ypoergo//*:KODIKOS_MIS)}</kodikosMis>
      <aaYpoergoy>{fn:data($Ypoergo//*:AA_YPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <tdyId>{fn:data($Ypoergo//*:TDY_ID)}</tdyId>
      <typeNewEk>{fn:data($Ypoergo//*:TYPE_NEW_EK)}</typeNewEk>
      <neaEkdosh>{fn:data($Ypoergo//*:NEA_EKDOSH)}</neaEkdosh>
      <actionTyp>{fn:data($Ypoergo//*:ACTION_TYP)}</actionTyp>
      <kodikosYpoergoy>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
    </Ypoergo> 
    }
 </ListYpoergon>
};

declare function tdy:GetAaYpoergouListForCopy($inbound as element()) as element(){
 <ListYpoergon xmlns="http://espa.gr/v6/tdy">
 {let $ListaYpoergon:=fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('YPOERGO'),
                   'SELECT DISTINCT
                    tdpy.aa_ypoergoy AS aaYpoergoy,
                    TDY.TITLOS_YPOERGOY AS titlosYpoergoy,
                    tdy.tdy_id AS idDeltioy,
                    TDY.kodikos_ypoergoy AS kodikos_Ypoergoy,
                    TDY.AA_TDY || ''.'' || TDY.AA_YPOEKDOSH AS ekdosh
                    FROM kps6_tdp_ypoerga tdpy, kps6_ypoerga tdy
                    WHERE tdpy.kodikos_ypoergoy = tdy.kodikos_ypoergoy
                    AND tdpy.id_tdp = kps6_core.get_trexon_deltio(tdy.kodikos_mis, 101)
                    AND tdy.kodikos_mis = ?
                    and NVL (?, tdpy.AA_YPOERGOY) = tdpy.AA_YPOERGOY
                    ORDER BY 1,3',
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="aaYpoergou"]/@value))
 return
  if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
   else for $Ypoergo in $ListaYpoergon return
   <Ypoergo> 
      <kodikosMis/>
      <aaYpoergoy>{fn:data($Ypoergo//*:AAYPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOSYPOERGOY)}</titlosYpoergoy>
      <tdyId>{fn:data($Ypoergo//*:IDDELTIOY)}</tdyId>  
      <typeNewEk/>
      <neaEkdosh>{fn:data($Ypoergo//*:EKDOSH)}</neaEkdosh>
      <actionTyp/>
      <kodikosYpoergoy>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
    </Ypoergo>   
 }   
 </ListYpoergon>
};

declare function tdy:GetElegxoiNomimotitasList($inbound as element()) as element(){

 <ListElegxonNomimotitas xmlns="http://espa.gr/v6/tdy">
 { let $ListaElegxnonNomimotitas := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('ELEGXOS'),
               'select distinct hdr.ID_PROEG proeg_aa, tropop.ekdosh_proeg ||''.'' ||tropop.ypoekdosh_proeg aa, 
                tropop.TITLOS_ypoekdoshs titlos,
                tropop.id_proeg_tropop
                FROM kps6_proegkriseis hdr, kps6_proeg_tropop tropop, kps6_proeg_ypoerga pyp
                WHERE hdr.id_proeg = tropop.id_proeg
                AND hdr.id_proeg = pyp.id_proeg
                and pyp.kodikos_YPOERGOY = ?
                and pyp.kodikos_mis = ?
                and tropop.proeg_eidos=5802
                and
                tropop.kodikos_eidoys_eishghshs in (5761,5763, 5766)
                and
                (select  kps6_core.get_obj_status(tropop.id_proeg_tropop,135) from dual) = 304 
                 and 1=   case when 1= (select 1 from kps6_ypoerga y where  y.kodikos_ypoergoy= pyp.kodikos_YPOERGOY  AND   y.KODIKOS_MIS= pyp.kodikos_mis and aa_tdy =?  and kathgoria_ekdoshs = 5662)
                 and 0 = (select nvl ((select 1 from kps6_ypoerga y where  y.kodikos_ypoergoy= pyp.kodikos_YPOERGOY  AND   y.KODIKOS_MIS= pyp.kodikos_mis and y.obj_isxys =1 ),0) from dual) then 1
                 else To_Number(?)
                 end
                and
                tropop.id_proeg_tropop not in (
                select distinct
                KPS6_YPOERGA.KODIKOS_PROEG from kps6_ypoerga
                where
                kps6_ypoerga.kodikos_ypoergoy= ?
                AND KPS6_YPOERGA.KODIKOS_MIS= ?
                and
                KPS6_YPOERGA.AA_TDY !=  ?
                and KPS6_YPOERGA.KODIKOS_PROEG is not null
                and obj_status_id!= 309 ) 
                UNION
                select distinct hdr.ID_PROEG proeg_aa, tropop.ekdosh_proeg ||''.''|| tropop.ypoekdosh_proeg aa, 
                tropop.TITLOS_ypoekdoshs titlos, tropop.id_proeg_tropop
                FROM kps6_proegkriseis hdr, kps6_proeg_tropop
                tropop, kps6_proeg_ypoerga pyp
                WHERE hdr.id_proeg = tropop.id_proeg
                AND hdr.id_proeg = pyp.id_proeg
                and pyp.kodikos_YPOERGOY = ?
                and pyp.kodikos_mis = ?
                and tropop.proeg_eidos=5803
                and tropop.kodikos_eidoys_eishghshs in (5761,5763)
                and
                (select  kps6_core.get_obj_status(tropop.id_proeg_tropop,135) from dual) = 304 
                 and 1= case when 1= (select 1 from kps6_ypoerga y where y.kodikos_ypoergoy= pyp.kodikos_YPOERGOY AND  y.KODIKOS_MIS= pyp.kodikos_mis and aa_tdy =?  and kathgoria_ekdoshs = 5662)
                 and 0 = (select nvl ((select 1 from kps6_ypoerga y where y.kodikos_ypoergoy= pyp.kodikos_YPOERGOY  AND   y.KODIKOS_MIS= pyp.kodikos_mis and y.obj_isxys =1),0) from dual) then  1
                 else To_Number(?)
                 end
                and tropop.id_proeg_tropop not in (
                select distinct
                KPS6_YPOERGA.KODIKOS_PROEG
                from kps6_ypoerga
                where
                kps6_ypoerga.kodikos_ypoergoy= ?
                AND
                KPS6_YPOERGA.KODIKOS_MIS= ?
                and
                KPS6_YPOERGA.AA_TDY != ?
                and
                KPS6_YPOERGA.KODIKOS_PROEG is not null
	        and obj_status_id != 309) ',
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoergoy"]/@value)
                )
   return
    if (fn:not($ListaElegxnonNomimotitas/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
     for $Elegxos in $ListaElegxnonNomimotitas return
      <ElegxosNomimotitas>
       <aaProegrisis>{fn:data($Elegxos//*:PROEG_AA)}</aaProegrisis>
       <titlos>{fn:data($Elegxos//*:TITLOS)}</titlos>
       <aa>{fn:data($Elegxos//*:AA)}</aa>
       <idProegTropop>{fn:data($Elegxos//*:ID_PROEG_TROPOP)}</idProegTropop>
      </ElegxosNomimotitas>
 }
 </ListElegxonNomimotitas>
};

declare function tdy:GetMeepCount($inbound as element()) as element(){
  <MeepCount xmlns="http://espa.gr/v6/tdy">
   {xs:unsignedShort(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('MEEP-COUNT'),
               'select count(*) as cnt_meep
                from kps6_tdp_ypoerga tdpYp,
                kps6_list_values_sysxetismoi listsysx
                where listsysx.sysx_kathg = 59465 
                and listsysx.list_value_id_a = tdpYp.eidos_ypoergoy 
                and tdpYp.id_tdp = kps6_core.get_max_aa(?, 101) 
                and tdpYp.kodikos_ypoergoy = ?',
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value))//*:CNT_MEEP)
  }
  </MeepCount>
};

declare function tdy:GetMeepCountEkdoseis($inbound as element()) as element(){
  <MeepCount xmlns="http://espa.gr/v6/tdy">
   {xs:unsignedShort(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('MEEP-COUNT'),
               'select count(*) as cnt_meep_not_null
                from kps6_ypoerga y
                where y.kodikos_ypoergoy = ?
                and (y.aa_tdy != ? OR  (y.aa_tdy = ? AND  y.aa_ypoekdosh != ?))
                and nvl(PERIORISMOI_MEEP,65000) != 65000',
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaTdy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaTdy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaYpoekdosh"]/@value))//*:CNT_MEEP_NOT_NULL)
  }
  </MeepCount>
};

declare function tdy:GetGeoList($inbound as element()) as element(){
 <GeoList xmlns="http://espa.gr/v6/tdy">
 { let $ListaGeo := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('GEO-ITEM'),
                     'SELECT DISTINCT all_geo.id_geo, g.id_perif, g.per_perif, g.id_nomos,
                      g.per_nomos, g.id_dhmos, g.perigrafh per_dhmos, g.kodikos_nuts,
                      all_geo.epipedo
                      FROM (SELECT id_geo,epipedo
                      FROM  kps6_c_geografia
                      WHERE id_geo IN (SELECT id_geo
                      FROM kps6_tdp_categories
                      WHERE id_geo IS NOT NULL
                      AND kps6_tdp_categories.id_tdp = 
                      (SELECT MAX (b.id_tdp) AS object_id
                      FROM kps6_tdp b
                      WHERE b.kodikos_mis = ? 
                      and b.tdp_ekdosh > 0 
                      and id_tdp>0 and obj_status_id is not null
                      and obj_status_id !=309 ))) all_geo,
                      v6_c_geografia_denorm g
                      WHERE  all_geo.id_geo = g.id_geo
                      ORDER  BY all_geo.epipedo, g.per_perif, g.per_nomos,  g.perigrafh',
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value))
  return                      
   if (fn:not($ListaGeo/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $GeoItem in $ListaGeo return 
   <GeoItem>
    <kodikosPerifereias/>
    <kodikosNomou>{fn:data($GeoItem//*:PER_NOMOS)}</kodikosNomou>
    <kodikosNuts>{fn:data($GeoItem//*:KODIKOS_NUTS)}</kodikosNuts>
    <kodikosNutsNomou/>
    <labelPerifereiaNomos></labelPerifereiaNomos>
    <idGeo>{fn:data($GeoItem//*:ID_GEO)}</idGeo>
    <idCountry/>
    <idKratid/>
    <idPerif>{fn:data($GeoItem//*:ID_PERIF)}</idPerif>
    <idNomos>{if ($GeoItem//*:ID_NOMOS) then fn:data($GeoItem//*:ID_NOMOS) else 0}</idNomos>
    <idDhmos>{if ($GeoItem//*:ID_DHMOS) then fn:data($GeoItem//*:ID_DHMOS) else 0}</idDhmos>
    <perigrafhPerifereias>{fn:data($GeoItem//*:PER_PERIF)}</perigrafhPerifereias>
    <perigrafhNomou>{fn:data($GeoItem//*:PER_NOMOS)}</perigrafhNomou>
    <idDhmosPerigrafh/>
    <epipedo>{fn:data($GeoItem//*:EPIPEDO)}</epipedo>
    <aaProsklhshs/>
    <idKatper/>
    <perigrafh/>
    <perigrafhKratid/>
    <parent/>
   </GeoItem>
 }
 </GeoList>
};

(: Ίδια όπως η /generic/getKatastaseisDeliou/{CategoryID} :)
declare function tdy:GetKatastaseisDeltio() as element(){
 <ListaKatastaseon xmlns="http://espa.gr/v6/tdy">
 {for $Katastasi in fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('KATASTASI'),
               'SELECT
                kps6_object_category_status.object_status_id,
                kps6_object_category_status.object_status_name,
                kps6_object_category_status.object_status_name_en
                FROM
                MASTER6.kps6_object_categories,
                kps6_object_category_status
                WHERE
                kps6_object_category_status.object_category_id (+) = kps6_object_categories.object_category_id
                AND kps6_object_categories.object_category_id = 103
                ORDER BY
                kps6_object_category_status.object_status_aa') return
  <KatastasiDeltiou>
   <id>{fn:data($Katastasi//*:OBJECT_STATUS_ID)}</id>
   <description>{fn:data($Katastasi//*:OBJECT_STATUS_NAME)}</description>
   <descriptionEn>{fn:data($Katastasi//*:OBJECT_STATUS_NAME_EN)}</descriptionEn>
  </KatastasiDeltiou>                
                
 }
 </ListaKatastaseon>
};

declare function tdy:GetYpoerga($inbound as element()) as element(){
  <ListaYpoergon xmlns="http://espa.gr/v6/tdy">
  {let $ListaYpoergon:= fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Ypoergo'),
              'select aa_ypoergoy , titlos_ypoergoy, KODIKOS_YPOERGOY
               from kps6_tdp_ypoerga
               where kps6_tdp_ypoerga.id_tdp = kps6_core.get_trexon_deltio(kodikos_mis, 101)
                 and kodikos_mis=?',
                 xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value))
   return
    if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else
   for $Ypoergo in $ListaYpoergon return
    <Ypoergo>
      <kodikos>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikos>      
      <perigrafh>{fn:data($Ypoergo//*:TITLOS_YPOERGOY)}</perigrafh>
      <aa>{fn:data($Ypoergo//*:AA_YPOERGOY)}</aa>
      <misCode/>
      <eidosYpoergou/>
      <thesmikoPlaisio/>
      <ypoekdosh/>
      <aaYpoergoy/>
      <idTdpYpoerga/>
      <hasSelect>1</hasSelect>
      <hasInsert>1</hasInsert>
      <hasUpdate>1</hasUpdate>
      <hasDelete>1</hasDelete>
    </Ypoergo>
  }
  </ListaYpoergon>
};

declare function tdy:GetYpoergaByKodikos($inbound as element()) as element(){
  <ListaYpoergon xmlns="http://espa.gr/v6/tdy">
  {let $ListaYpoergon:= fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Ypoergo'),
              'select aa_ypoergoy , titlos_ypoergoy, KODIKOS_YPOERGOY
               from kps6_tdp_ypoerga
               where kps6_tdp_ypoerga.id_tdp = kps6_core.get_trexon_deltio(kodikos_mis, 101)
                 and kodikos_mis=?',
                 xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value))
   return
    if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else
   for $Ypoergo in $ListaYpoergon return
    <Ypoergo>
      <aaYpoergoy>{fn:data($Ypoergo//*:AA_YPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <kodikosYpoergoy>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
      <kodikos>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikos> 
    </Ypoergo>
  }
  </ListaYpoergon>
};

declare function tdy:GetKatigoriesDapanis($inbound as element()) as element(){
  <ListaKatigorionDapanis xmlns="http://espa.gr/v6/tdy">
  {let $ListaKatigorionDapanis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('KatigoriaDapanis'),
              'SELECT DISTINCT KPS6_TDP_DAPANES_APLOP.ID_KATHGORIA_DAPANHS, dap.kodikos_dapanhs,
                dap.perigrafh_kathgoria_dapanhs,
                KPS6_TDP_DAPANES_APLOP.POSOSTO,
                kps6_c_monadiaia_kosth.id_unco id_unco,
                KPS6_TDP_DAPANES_APLOP.kostos_monadas Monadiaio_Kostos,
                kps6_c_monades_metrhshs.perigrafh MOnada_Metrhshs,
                kps6_c_monadiaia_kosth.perigrafh Perigrafh_Monadas,
                KPS6_TDP_DAPANES_APLOP.SXOLIA oroi_efarmoghs, 
                kps6_tdp.kodikos_mis mis, dap.ID_XARAKTHRISTIKO_DAPANHS id_xar
                FROM kps6_tdp, kps6_tdp_dapanes_aplop
                inner join kps6_epileksimes_dapanes dap on
                    (dap.id_kathgoria_dapanhs=kps6_tdp_dapanes_aplop.id_kathgoria_dapanhs)
                left outer JOIN kps6_c_monadiaia_kosth on 
                    (kps6_c_monadiaia_kosth.id_unco=kps6_tdp_dapanes_aplop.id_unco)
                left outer JOIN kps6_c_monades_metrhshs on 
                    ( kps6_c_monades_metrhshs.id_mm = kps6_c_monadiaia_kosth.id_mm)
                WHERE kps6_tdp.id_tdp= KPS6_TDP_DAPANES_APLOP.ID_TDP
                and kps6_tdp.id_tdp=kps6_core.get_trexon_deltio(kps6_tdp.kodikos_mis,101)
                and kps6_tdp.kodikos_mis= ?
                order by 1',
                 xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="mis"]/@value))
   return
    if (fn:not($ListaKatigorionDapanis/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $KatigoriaDapanis in $ListaKatigorionDapanis return 
    <KatigoriaDapanis>
      <idKatigoriaDapanis>{fn:data($KatigoriaDapanis//*:ID_KATHGORIA_DAPANHS)}</idKatigoriaDapanis>
      <kodikosDapanhs>{fn:data($KatigoriaDapanis//*:KODIKOS_DAPANHS)}</kodikosDapanhs>
      <perigrafiKatDapanis>{fn:data($KatigoriaDapanis//*:PERIGRAFH_KATHGORIA_DAPANHS)}</perigrafiKatDapanis>
      <pososto>{fn:data($KatigoriaDapanis//*:POSOSTO)}</pososto>
      <idUnco>{fn:data($KatigoriaDapanis//*:ID_UNCO)}</idUnco>
      <monadiaioKostos>{fn:data($KatigoriaDapanis//*:MONADIAIO_KOSTOS)}</monadiaioKostos>
      <monadaMetrhshs>{fn:data($KatigoriaDapanis//*:MONADA_METRHSHS)}</monadaMetrhshs>
      <perigrafiMonadas>{fn:data($KatigoriaDapanis//*:PERIGRAFH_MONADAS)}</perigrafiMonadas>
      <oroiEfarmogis>{fn:data($KatigoriaDapanis//*:OROI_EFARMOGHS)}</oroiEfarmogis>
      <mis>{fn:data($KatigoriaDapanis//*:MIS)}</mis>
      <idXaraktiristikoDapanis>{fn:data($KatigoriaDapanis//*:ID_XAR)}</idXaraktiristikoDapanis>
    </KatigoriaDapanis>
  }
  </ListaKatigorionDapanis>
};

declare function tdy:GetAplopoimenoKostos($inbound as element()) as element(){
<ListaKatigorionDapanis xmlns="http://espa.gr/v6/tdy">
  {let $ListaAplopoimenoKostous := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('KatigoriaDapanis'),
               'select b.id_kathgoria_dapanhs id,b.kodikos_dapanhs 
                kodikos_dapanhs,b.perigrafh_kathgoria_dapanhs 
                perigrafh,B.FLAG_ERGO_YPOERGO flag_ypoergo,B.ID_EIDOS_DAPANHS 
                eidos_dapanhs,B.ID_XARAKTHRISTIKO_DAPANHS 
                xarakthristiko_dapanhs,B.PLAFON_POSOSTO plafon,B.FLAG_PERIGRAFH 
                flag_perigrafh,b.FLAG_APLOPOIHMENO_KOSTOS 
                from kps6_tdp_dd_ana_kathg_dapanon a, 
                kps6_epileksimes_dapanes b, 
                kps6_tdp_ypoerga tdpypo, 
                kps6_list_values_sysxetismoi sysx 
                where a.id_kathgoria_dapanhs=b.id_kathgoria_dapanhs 
                and a.ID_TDP=KPS6_CORE.GET_MAX_AA(?,101) 
                and tdpypo.id_tdp=a.id_tdp 
                and TDPYPO.KODIKOS_YPOERGOY=? 
                and TDPYPO.EIDOS_YPOERGOY=SYSX.LIST_VALUE_ID_A  
                and A.ID_KATHGORIA_DAPANHS=sysx.list_value_id_b 
                AND SYSX.SYSX_KATHG=59450 
                and B.ID_EIDOS_DAPANHS=5352 
                ORDER BY 2',
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="mis"]/@value),
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="ypoergo"]/@value))
   return
    if (fn:not($ListaAplopoimenoKostous/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Kostos in $ListaAplopoimenoKostous return 
    <KatigoriaDapanis>
      <id>{fn:data($Kostos//*:ID)}</id>
      <kodikosDapanhs>{fn:data($Kostos//*:KODIKOS_DAPANHS)}</kodikosDapanhs>
      <perigrafh>{fn:data($Kostos//*:PERIGRAFH)}</perigrafh>
      <flagYpoergo>{fn:data($Kostos//*:FLAG_YPOERGO)}</flagYpoergo>
      <eidosDapanhs>{fn:data($Kostos//*:EIDOS_DAPANHS)}</eidosDapanhs>
      <xarakthristikoDapanhs>{fn:data($Kostos//*:XARAKTHRISTIKO_DAPANHS)}</xarakthristikoDapanhs>
      <plafon>{fn:data($Kostos//*:PLAFON)}</plafon>
      <flagPerigrafh>{fn:data($Kostos//*:FLAG_PERIGRAFH)}</flagPerigrafh>
      <flagAplopoiimenoKostos>{fn:data($Kostos//*:FLAG_APLOPOIHMENO_KOSTOS)}</flagAplopoiimenoKostos>
    </KatigoriaDapanis>
  }
  </ListaKatigorionDapanis>
};

declare function tdy:GetErotimata() as element(){
<ListaErotimaton xmlns="http://espa.gr/v6/tdy">
  {let $ListaErotimaton := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('YPOERGO'),
               'select DISTINCT  id_erothma ||list_value_id id_erot_list, id_erothma, list_value_id, list_value_name, list_value_name_en, list_value_aa  
                from KPS6_CHECKLISTS_TEMPLATE b, KPS6_LIST_CATEGORIES_VALUES a   
                where a.list_category_id = b.list_category_id 
                  and a.is_active = 1 
                order by list_value_id')
   return
    if (fn:not($ListaErotimaton/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Erotima in $ListaErotimaton return 
    <Erotima>
      <idErotList>{fn:data($Erotima//*:ID_EROT_LIST)}</idErotList>
      <idErothma>{fn:data($Erotima//*:ID_EROTHMA)}</idErothma>
      <listValueId>{fn:data($Erotima//*:LIST_VALUE_ID)}</listValueId>
      <listValueName>{fn:data($Erotima//*:LIST_VALUE_NAME)}</listValueName>
      <listValueNameEn>{fn:data($Erotima//*:LIST_VALUE_NAME_EN)}</listValueNameEn>
      <listValueAa>{fn:data($Erotima//*:LIST_VALUE_AA)}</listValueAa>
    </Erotima>
  }
  </ListaErotimaton>
};

declare function tdy:GetYpoergoInfo($inbound as element()) as element(){
<ListaYpoergon xmlns="http://espa.gr/v6/tdy">
{let $ListaYpoergon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('YPOERGO'),
               'Select aa_ypoergoy , titlos_ypoergoy, KODIKOS_YPOERGOY 
                from kps6_tdp_ypoerga 
                where kps6_tdp_ypoerga.id_tdp = kps6_core.get_trexon_deltio(kodikos_mis, 101) and 
                    kodikos_mis= ?',
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value))
   return
    if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Ypoergo in $ListaYpoergon return 
    <Ypoergo>
      <aaYpoergoy>{fn:data($Ypoergo//*:AA_YPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <kodikosYpoergoyY>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikosYpoergoyY>
    </Ypoergo>
  }
</ListaYpoergon>
};

declare function tdy:GetEti($inbound as element()) as element(){
<ListaEton xmlns="http://espa.gr/v6/tdy">
  {let $ListaEton := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Etos'),
                     'select eth.id_etos as etos 
                      from kps6_c_eth_espa eth, kps6_tdp tdp 
                      where eth.id_etos between extract( year from tdp.date_enarkshs_ergoy) 
                        and extract(year from tdp.date_lhkshs_ergoy)
                        and  tdp.kodikos_mis = ?
                        and tdp.obj_isxys = 1 
                      union 
                      select a.etos as etos 
                      from kps6_ypoe_katanomh a 
                      where a.tdy_id = ? 
                      order by etos',
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                      xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="tdyId"]/@value))
   return
    if (fn:not($ListaEton/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Etos in $ListaEton return 
      <Etos>{fn:data($Etos//*:ETOS)}</Etos>
  }
  </ListaEton>
};

declare function tdy:GetKatigoriesDapanon($inbound as element()) as element(){
<ListaKatigorionDapanis xmlns="http://espa.gr/v6/tdy">
  {let $ListaKatigorionDapanon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('KatigoriaDapanis'), 
                     'select b.id_kathgoria_dapanhs id,b.kodikos_dapanhs kodikos_dapanhs, 
                             b.perigrafh_kathgoria_dapanhs perigrafh,B.FLAG_ERGO_YPOERGO flag_ypoergo, 
                             B.ID_EIDOS_DAPANHS eidos_dapanhs,B.ID_XARAKTHRISTIKO_DAPANHS xarakthristiko_dapanhs, 
                             B.PLAFON_POSOSTO plafon,B.FLAG_PERIGRAFH flag_perigrafh 
                      from kps6_tdp_dd_ana_kathg_dapanon a, kps6_epileksimes_dapanes b, kps6_tdp_ypoerga tdpypo, 
                      kps6_list_values_sysxetismoi sysx 
                      where a.id_kathgoria_dapanhs=b.id_kathgoria_dapanhs 
                        and a.ID_TDP=KPS6_CORE.GET_TREXON_DELTIO(?,101) 
			and tdpypo.id_tdp =a.id_tdp 
			and TDPYPO.KODIKOS_YPOERGOY=? 
			and TDPYPO.EIDOS_YPOERGOY=SYSX.LIST_VALUE_ID_A 
			and A.ID_KATHGORIA_DAPANHS=sysx.list_value_id_b 
			AND SYSX.SYSX_KATHG=59450 
			and B.ID_EIDOS_DAPANHS!=5352 
                      union 
                      select b.id_kathgoria_dapanhs id,b.kodikos_dapanhs kodikos_dapanhs, 
                             b.perigrafh_kathgoria_dapanhs perigrafh,B.FLAG_ERGO_YPOERGO flag_ypoergo, 
                             B.ID_EIDOS_DAPANHS eidos_dapanhs,B.ID_XARAKTHRISTIKO_DAPANHS xarakthristiko_dapanhs, 
                             B.PLAFON_POSOSTO plafon,B.FLAG_PERIGRAFH flag_perigrafh 
                      from kps6_epileksimes_dapanes b, kps6_tdp_ypoerga tdpypo, kps6_list_values_sysxetismoi sysx 
                      where tdpypo.ID_TDP=KPS6_CORE.GET_TREXON_DELTIO(?,101) 
			and TDPYPO.KODIKOS_YPOERGOY=? 
			and TDPYPO.EIDOS_YPOERGOY=SYSX.LIST_VALUE_ID_A 
			and b.ID_KATHGORIA_DAPANHS=sysx.list_value_id_b 
			AND SYSX.SYSX_KATHG=59451 
			and nvl(( select distinct 1 from 
				( select b.id_kathgoria_dapanhs id, b.kodikos_dapanhs kodikos_dapanhs, 
				         b.perigrafh_kathgoria_dapanhs perigrafh,B.FLAG_ERGO_YPOERGO flag_ypoergo, 
				         B.ID_EIDOS_DAPANHS eidos_dapanhs,B.ID_XARAKTHRISTIKO_DAPANHS xarakthristiko_dapanhs, 
				         B.PLAFON_POSOSTO plafon,B.FLAG_PERIGRAFH flag_perigrafh 
                                  from kps6_tdp_dd_ana_kathg_dapanon a, kps6_epileksimes_dapanes b, kps6_tdp_ypoerga tdpypo, 
                                       kps6_list_values_sysxetismoi sysx 
				  where a.id_kathgoria_dapanhs=b.id_kathgoria_dapanhs 
                                    and a.ID_TDP=KPS6_CORE.GET_TREXON_DELTIO(?,101) 
				    and tdpypo.id_tdp =a.id_tdp 
                                    and TDPYPO.KODIKOS_YPOERGOY=? 
                                    and TDPYPO.EIDOS_YPOERGOY=SYSX.LIST_VALUE_ID_A 
                                    and A.ID_KATHGORIA_DAPANHS=sysx.list_value_id_b 
                                    AND SYSX.SYSX_KATHG=59450 
                                    and B.ID_EIDOS_DAPANHS!=5352 
                                    and A.ID_KATHGORIA_DAPANHS not in  
                                            (select distinct KPS6_EPILEKSIMES_DAPANES.ID_PARENT  from kps6_epileksimes_dapanes ))),0)!=1 
                     union 
                     select b.id_kathgoria_dapanhs id,b.kodikos_dapanhs kodikos_dapanhs, 
                            b.perigrafh_kathgoria_dapanhs perigrafh,B.FLAG_ERGO_YPOERGO flag_ypoergo, 
                            B.ID_EIDOS_DAPANHS eidos_dapanhs,B.ID_XARAKTHRISTIKO_DAPANHS xarakthristiko_dapanhs, 
                            B.PLAFON_POSOSTO plafon,B.FLAG_PERIGRAFH flag_perigrafh 
                    from KPS6_YPOE_EPILEKSIMES a, kps6_epileksimes_dapanes b 
                    where a.id_kathgoria_dapanhs=b.id_kathgoria_dapanhs 
                      and ID_EIDOS_DAPANHS!=5352 
                      and a.tdy_id=? 
                    ORDER BY 2',
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergou"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergou"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergou"]/@value),
                    xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="tdyid"]/@value))
   return
    if (fn:not($ListaKatigorionDapanon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $KatigoriaDapanis in $ListaKatigorionDapanon return 
    <KatigoriaDapanis>
      <id>{fn:data($KatigoriaDapanis//*:ID)}</id>
      <kodikosDapanhs>{fn:data($KatigoriaDapanis//*:KODIKOS_DAPANHS)}</kodikosDapanhs>
      <perigrafh>{fn:data($KatigoriaDapanis//*:PERIGRAFH)}</perigrafh>
      <flagYpoergo>{fn:data($KatigoriaDapanis//*:FLAG_YPOERGO)}</flagYpoergo>
      <eidosDapanhs>{fn:data($KatigoriaDapanis//*:EIDOS_DAPANHS)}</eidosDapanhs>
      <xarakthristikoDapanhs>{fn:data($KatigoriaDapanis//*:XARAKTHRISTIKO_DAPANHS)}</xarakthristikoDapanhs>
      <plafon>{fn:data($KatigoriaDapanis//*:PLAFON)}</plafon>
      <flagPerigrafh>{fn:data($KatigoriaDapanis//*:FLAG_PERIGRAFH)}</flagPerigrafh>
      <flagAplopoiimenoKostos/>
    </KatigoriaDapanis>
  }
  </ListaKatigorionDapanis>
};

declare function tdy:GetListesTimon($mis as xs:unsignedInt , $aa as xs:unsignedInt) as element(){
<ListaTimon xmlns="http://espa.gr/v6/tdy">
  {let $ListaTimon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Timi'), 
                     'select list_value_id,list_value_name,list_value_kodikos_display,is_active 
                      from kps6_list_categories_values, kps6_list_values_sysxetismoi 
                      where KPS6_LIST_CATEGORIES_VALUES.LIST_VALUE_ID=KPS6_LIST_VALUES_SYSXETISMOI.LIST_VALUE_ID_B 
                        and KPS6_LIST_VALUES_SYSXETISMOI.SYSX_KATHG=59492  
                        and KPS6_LIST_VALUES_SYSXETISMOI.LIST_VALUE_ID_A =  
                                  (select EIDOS_YPOERGOY 
                                   from kps6_tdp_ypoerga inner join kps6_tdp on kps6_tdp.id_tdp= kps6_tdp_ypoerga.id_tdp
                                   where kps6_tdp_ypoerga.kodikos_mis = ?
                                     and kodikos_ypoergoy = ?
                                     and KPS6_TDP.OBJ_ISXYS = 1) 
                        and kps6_list_categories_values.is_active = 1 
                      order by list_value_aa',$mis, $aa )
   return
    if (fn:not($ListaTimon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Timi in $ListaTimon return 
    <Timi>
      <list_value_id>{fn:data($Timi//*:LIST_VALUE_ID)}</list_value_id>
      <list_value_name>{fn:data($Timi//*:LIST_VALUE_NAME)}</list_value_name>
      <list_value_kodikos_display>{fn:data($Timi//*:LIST_VALUE_KODIKOS_DISPLAY)}</list_value_kodikos_display>
      <is_active>{fn:boolean($Timi//*:IS_ACTIVE)}</is_active>
    </Timi>
  }
  </ListaTimon>
};

declare function tdy:GetTitloYpoergoy($inbound as element()) as element(){
  <TitlosYpoergoy xmlns="http://espa.gr/v6/tdy">
      {let $TitlosYpoergou :=fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Title'),
              'select titlos_ypoergoy 
              from kps6_tdp_ypoerga a  
               where a.kodikos_mis = ? 
                 and a.id_tdp in (select KPS6_core.get_max_aa(?,101) from dual) 
                 and a.kodikos_ypoergoy=?',
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value))//*:TITLOS_YPOERGOY
      return
        <title>{fn:data($TitlosYpoergou)}</title>
      }
  </TitlosYpoergoy>
};

declare function tdy:GetProsklisis() as element(){
<ListaProskliseon xmlns="http://espa.gr/v6/tdy">
  {let $Listaproskliseon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Prosklisi'),
               'select distinct kodikos_proskl_forea, id_prosklhshs, kodikos_prosklhshs, titlos, titlos_en from
                kps6_prosklhseis')
   return
    if (fn:not($Listaproskliseon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Prosklisi in $Listaproskliseon return 
    <Prosklisi>
      <kodikosProsklhshs>{fn:data($Prosklisi//*:KODIKOS_PROSKLHSHS)}</kodikosProsklhshs>
      <titlos>{fn:data($Prosklisi//*:TITLOS)}</titlos>
      <ekdosh/>
      <epKodikos/>
      <ypoprKodikos/>
      <metroKodikos/>
      <foreasKodikos/>
      <perigrafhForeaProsklhshs/>
      <kodikosProsklForea>{fn:data($Prosklisi//*:KODIKOS_PROSKL_FOREA)}</kodikosProsklForea>
      <idProsklhshs>{fn:data($Prosklisi//*:ID_PROSKLHSHS)}</idProsklhshs>
      <flagMicrodata>0</flagMicrodata>
      <dateTo/>
      <userPermissionsMap/>
    </Prosklisi>
  }
  </ListaProskliseon>
};




declare function tdy:GetMis($inbound as element()) as element(){
 <ListaMis xmlns="http://espa.gr/v6/tdy">
  {let $ListaMis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Mis'),
               'SELECT t.kodikos_mis, t.titlos,t.titlos_ksenos,  
                (select   (to_char( kps6_core.get_obj_status_date(t.KODIKOS_MIS ,1, 205) , ''dd/mm/rrrr''))  
                from dual) DATE_EntaksHS,   
                t.TDP_EKDOSH || ''.'' || t.tdp_ypoekdosh ekdosh_TDP 
                FROM KPS6_TDP t  
                WHERE  t.tdp_ekdosh>0 
                and lpad(t.tdp_ekdosh,2,''0'' )|| ''.'' || lpad(t.tdp_ypoekdosh,2,''0'') =
                (select max(lpad(ttt.tdp_ekdosh,2,''0'') || ''.'' || lpad(ttt.tdp_ypoekdosh,2,''0'')) 
                 from kps6_tdp ttt 
                 where ttt.kodikos_mis=t.kodikos_mis  
                   and ttt.obj_status_id not in (300,306,309,310)   
                   and  ttt.tdp_ekdosh>0  
                   and (select kps6_core.get_obj_status( t.kodikos_mis, 1) from dual) = 205) 
                   and  t.epixeirimatikotita != 5243 
                   and NVL (?, t.kodikos_mis) = t.kodikos_mis 
                order by 1',xs:unsignedInt($inbound/ctx:transport/ctx:request/http:query-parameters/http:parameter[@name="kodikosMis"]/@value))
   return
    if (fn:not($ListaMis/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Mis in $ListaMis return 
    <Mis>
      <kodikosMis>{fn:data($Mis//*:KODIKOS_MIS)}</kodikosMis>
      <titlos>{fn:data($Mis//*:TITLOS)}</titlos>
      <ekdosh/>
      <ypoEkdosh/>
      <titlosKsenos>{fn:data($Mis//*:TITLOS_KSENOS)}</titlosKsenos>
      <ekdosiTdp>{fn:data($Mis//*:EKDOSH_TDP)}</ekdosiTdp>
      <dateEntaksis>{fn:data($Mis//*:DATE_ENTAKSHS)}</dateEntaksis>
      <flagAmkaAfm/>
    </Mis>
  }
  </ListaMis>
};


declare function tdy:map-db-to-get-response($db-response as element()) 
as element()(:: schema-element(tdy-response:TDYGetResponse)::) {
 <TDYGetResponse xmlns='http://espa.gr/v6/tdy'>
    <ERROR_CODE/>
    <ERROR_MESSAGE/>
    <DATA>
    {if ($db-response//tdy-db:Kps6Ypoerga/node()) then 
      <KPS6_YPOERGA> 
        <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
        <KODIKOS_MIS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:kodikosMis)}</KODIKOS_MIS>
        <KODIKOS_YPOERGOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:kodikosYpoergoy)}</KODIKOS_YPOERGOY>
        <AA_YPOERGOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:aaYpoergoy)}</AA_YPOERGOY>
        <AA_TDY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:aaTdy)}</AA_TDY>
        <AA_YPOEKDOSH>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:aaYpoekdosh)}</AA_YPOEKDOSH>
        <KATHGORIA_EKDOSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:kathgoriaEkdoshs)}</KATHGORIA_EKDOSHS>
        <TITLOS_YPOERGOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:titlosYpoergoy)}</TITLOS_YPOERGOY>
        <KODIKOS_PROEG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:kodikosProeg)}</KODIKOS_PROEG>
        <TEXNIKH_PERIGRAFH>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:texnikhPerigrafh)}</TEXNIKH_PERIGRAFH>
        <AR_PROTOK_DA>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:arProtokDa)}</AR_PROTOK_DA>
        <DATE_CREATION>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:dateCreation)}</DATE_CREATION>
        <DATE_MET_YPOVOLHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:dateMetYpovolhs)}</DATE_MET_YPOVOLHS>
        <DATE_YPOVOLIS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateYpovolis)}</DATE_YPOVOLIS>
        <DATE_EPILEKSIMOTHTAS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateEpileksimothtas)}</DATE_EPILEKSIMOTHTAS>
        <DATE_ANALHPSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateAnalhpshs)}</DATE_ANALHPSHS>
        <DATE_LHKSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateLhkshs)}</DATE_LHKSHS>
        <DATE_TROPOP>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateTropop)}</DATE_TROPOP>
        <KODIKOS_EPIVLEPOYSAS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:kodikosEpivlepoysas)}</KODIKOS_EPIVLEPOYSAS>
        <PARATHRHSEIS_KATAXOR_TDY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:parathrhseisKataxorTdy)}</PARATHRHSEIS_KATAXOR_TDY>
        <EIDOS_ANATHESHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:eidosAnatheshs)}</EIDOS_ANATHESHS>
        <KODIKOS_DIKAIOYXOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:kodikosDikaioyxos)}</KODIKOS_DIKAIOYXOS>
        <ELEGXOS_AATDP>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:elegxosAatdp)}</ELEGXOS_AATDP>
        <ONOMA_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:onomaYpeythinoy)}</ONOMA_YPEYTHINOY>
        <THESH_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:theshYpeythinoy)}</THESH_YPEYTHINOY>
        <DIEYTHYNSH_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dieythynshYpeythinoy)}</DIEYTHYNSH_YPEYTHINOY>
        <SPECIALITY_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:specialityYpeythinoy)}</SPECIALITY_YPEYTHINOY>
        <THL_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:thlYpeythinoy)}</THL_YPEYTHINOY>
        <FAX_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:faxYpeythinoy)}</FAX_YPEYTHINOY>
        <EMAIL_YPEYTHINOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:emailYpeythinoy)}</EMAIL_YPEYTHINOY>
        <PARATHRHSEIS_KATAXOR_TDY_DIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:parathrhseisKataxorTdyDik)}</PARATHRHSEIS_KATAXOR_TDY_DIK>
        <TITLOS_FOREA>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:titlosForea)}</TITLOS_FOREA>
        <ELEGXOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:elegxos)}</ELEGXOS>
        <KATASTASH_DELTIOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:katastashDeltioy)}</KATASTASH_DELTIOY>
        <KATASTASH_DELTIOY_DESCR>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:katastashDeltioyDescr)}</KATASTASH_DELTIOY_DESCR>
        <DATE_ELEGXOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:dateElegxoy)}</DATE_ELEGXOY>
        <ID_TDY_SYMPLHROMATIKHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:idTdySymplhromatikhs)}</ID_TDY_SYMPLHROMATIKHS>
        <TYPOS_TDY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:typosTdy)}</TYPOS_TDY>
        <AITIOLOGIA_YPOEKDOSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:aitiologiaYpoekdoshs)}</AITIOLOGIA_YPOEKDOSHS>
        <FLAG_TROP_TIMETABLE>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:flagTropTimetable)}</FLAG_TROP_TIMETABLE>
        <FLAG_TROP_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:flagTropOik)}</FLAG_TROP_OIK>
        <FLAG_TROP_FYS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:flagTropFys)}</FLAG_TROP_FYS>
        <FLAG_TROP_ALLO>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:flagTropAllo)}</FLAG_TROP_ALLO>
        <KODIKOS_OIKONOMIKHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:kodikosOikonomikhs)}</KODIKOS_OIKONOMIKHS>
        <PERIGRAFH_OIKONOMIKHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:perigrafhOikonomikhs)}</PERIGRAFH_OIKONOMIKHS>
        <ONOMA_YPEYTHINOY_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:onomaYpeythinoyOik)}</ONOMA_YPEYTHINOY_OIK>
        <THESH_YPEYTHINOY_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:theshYpeythinoyOik)}</THESH_YPEYTHINOY_OIK>
        <DIEYTHYNSH_YPEYTHINOY_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dieythynshYpeythinoyOik)}</DIEYTHYNSH_YPEYTHINOY_OIK>
        <THL_YPEYTHINOY_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:thlYpeythinoyOik)}</THL_YPEYTHINOY_OIK>
        <EMAIL_YPEYTHINOY_OIK>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:emailYpeythinoyOik)}</EMAIL_YPEYTHINOY_OIK>
          <POSO_MH_ENISXYOMENH>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:posoMhEnisxyomenh)}</POSO_MH_ENISXYOMENH>
        <YPOE_ARXAIOLOGIA_FLAG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:ypoeArxaiologiaFlag)}</YPOE_ARXAIOLOGIA_FLAG>
        <YPOE_ENISXYSH_FLAG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:ypoeEnisxyshFlag)}</YPOE_ENISXYSH_FLAG>
        <FPA_ANAKTHSIMOS_FLAG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:fpaAnakthsimosFlag)}</FPA_ANAKTHSIMOS_FLAG>
        <PERIORISMOI_MEEP>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:periorismoiMeep)}</PERIORISMOI_MEEP>
        <DATE_MEEP>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:dateMeep)}</DATE_MEEP>
        <POSO_IDIOT>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:posoIdiot)}</POSO_IDIOT>
        <ST_FLAG/>
        <PROEG_AA>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:proegAa)}</PROEG_AA>
        <EKDOSH_PROEG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:ekdoshProeg)}</EKDOSH_PROEG>
        <TITLOS_PROEG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vs6TdyInfo/tdy-db:titlos)}</TITLOS_PROEG>
        <DIKAIOYXOS_YPOERGOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:dikaioyxosYpoergoy)}</DIKAIOYXOS_YPOERGOY>
        <FOREAS_PARAKOLOYTHISHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:foreasParakol)}</FOREAS_PARAKOLOYTHISHS>
        <TDP_ID_ATP>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:tdpIdAtp)}</TDP_ID_ATP>
        <RHTRA>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:rhtra)}</RHTRA>
        <PERIGRAFH_EPIVLEPOYSAS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:perigrafhEpivlepousas)}</PERIGRAFH_EPIVLEPOYSAS>
        <PROELEYSH_DELTIO>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:proelefshDeltio)}</PROELEYSH_DELTIO>
        <DA_TEXT>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:daText)}</DA_TEXT>
        <FLAG_AYTOMATI_EKGKRISH_TDY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:flagAytomatiEkgkrishTdy)}</FLAG_AYTOMATI_EKGKRISH_TDY>
        <KPS_KATALOGOS_ERGON>
         <EP_KODIKOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:epKodikos)}</EP_KODIKOS>
         <EP_TITLOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:epTitlos)}</EP_TITLOS>
         <YPOPROGR_KODIKOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:ypoprogrKodikos)}</YPOPROGR_KODIKOS>
         <YPOPROGR_TITLOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:ypoprogrTitlos)}</YPOPROGR_TITLOS>
         <KATASTASH_PRAKSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:katastashPrakshs)}</KATASTASH_PRAKSHS>
         <TITLOS_MIS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:titlosMis)}</TITLOS_MIS>
         <PROSKLHSH_KODIKOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:prosklhshKodikos)}</PROSKLHSH_KODIKOS>
         <TITLOS_PROSKLHSHS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:titlosProsklhshs)}</TITLOS_PROSKLHSHS>
         <EKXOR_KODIKOS>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:ekxorKodikos)}</EKXOR_KODIKOS>
         <EIDOS_YPOERGOY>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:eidosYpoergoy)}</EIDOS_YPOERGOY>
         <EIDOS_YPOERGOY_DESCR>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:eidosYpoergoyDescr)}</EIDOS_YPOERGOY_DESCR>
         <ORIZONTIO_YPOERGO_FLAG>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:vsTdyKatalogosErgonInfo/tdy-db:orizontioYpoergoFlag)}</ORIZONTIO_YPOERGO_FLAG>
         <FLAG_MEEP_ENABLE>{if (fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:periorismoiMeep)) then  1  else  0 }</FLAG_MEEP_ENABLE>
      </KPS_KATALOGOS_ERGON>
      {if ($db-response//tdy-db:Kps6YpoeAnadoxoi/node()) then 
       for $YpoAnadoxos in $db-response//tdy-db:Kps6YpoeAnadoxoi return
       <KPS6_YPOE_ANADOXOI>
        <YAN_ID>{fn:data($YpoAnadoxos/tdy-db:yanId)}</YAN_ID>
        <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
        <AFM>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:afm)}</AFM>
        <ADAM_SYMVASHS>{fn:data($YpoAnadoxos/tdy-db:adamSymvashs)}</ADAM_SYMVASHS>
        <ROLOS_ANADOXOU>{fn:data($YpoAnadoxos/tdy-db:rolosAnadoxou)}</ROLOS_ANADOXOU>
        <ENERGOS_ANADOXOS>{fn:data($YpoAnadoxos/tdy-db:energosAnadoxos)}</ENERGOS_ANADOXOS>
        <AITIOLOGIA_ANENERGOY>{fn:data($YpoAnadoxos/tdy-db:aitiologiaAnenergoy)}</AITIOLOGIA_ANENERGOY>
        <POSO_DD>{fn:data($YpoAnadoxos/tdy-db:posoDd)}</POSO_DD>
        <PARATHRHSEIS_KATAXOR_TDY_ANA>{fn:data($YpoAnadoxos/tdy-db:parathrhseisKataxorTdyAna)}</PARATHRHSEIS_KATAXOR_TDY_ANA>
        <ROLOS_ANADOXOU_DESCR>
         {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('LIST-CATEGORIES'),
                  'Select VAL.LIST_VALUE_NAME as col1  
                  from KPS6_LIST_CATEGORIES_VALUES val 
                  where VAL.LIST_VALUE_ID = ?',xs:unsignedInt(tdy:if-empty($YpoAnadoxos/tdy-db:rolosAnadoxou,0)))//*:LIST_VALUE_NAME)}           
        </ROLOS_ANADOXOU_DESCR>
        <KPS_ANADOXOI>
         <AFM>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:afm)}</AFM>
         <DOY>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:doy)}</DOY>
         <EPONYMIA>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:eponymia)}</EPONYMIA>
         <XRHSTHS_EISAG>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:xrhsthsEisag)}</XRHSTHS_EISAG>
         <HMEROM_EISAG>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:hmeromEisag)}</HMEROM_EISAG>
         <XRHSTHS_ENHM>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:xrhsthsEnhm)}</XRHSTHS_ENHM>
         <HMEROM_ENHM>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:hmeromEnhm)}</HMEROM_ENHM>
         <ELEGXOS>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:elegxos)}</ELEGXOS>
         <AFM_TEMP>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:afmTemp)}</AFM_TEMP>
         <DIEYTHYNSH>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:dieythynsh)}</DIEYTHYNSH>
         <FAX>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:fax)}</FAX>
         <POLH>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:polh)}</POLH>
         <TK>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:tk)}</TK>
         <EMAIL>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:email)}</EMAIL>
         <DIAKRITOS_TITLOS>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:diakritosTitlos)}</DIAKRITOS_TITLOS>
         <ENISX_EPIX>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:enisxEpix)}</ENISX_EPIX>
         <ANAD_DHM_SYMB>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:anadDhmsymb)}</ANAD_DHM_SYMB>
         <EGKYRO>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:egkyro)}</EGKYRO>
         <PROSOPO>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:prosopo)}</PROSOPO>
         <XENO_AFM>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:xenoAfm)}</XENO_AFM>
         <ENLYPOLOGOS_FLG>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:enlYpologosFlg)}</ENLYPOLOGOS_FLG>
         <ENL_DIKAIOYX_FLG>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:enlDikaioyxFlg)}</ENL_DIKAIOYX_FLG>
         <THL>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:thl)}</THL>
         <KODIKOS_DOY>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:kodikosDoy)}</KODIKOS_DOY>
         <MEGETHOS_EPIXEIRHSHS>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:megethosEpixeirhshs)}</MEGETHOS_EPIXEIRHSHS>
         <AFM_T>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:afmt)}</AFM_T>
         <FLAG_FYLO>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:flagFylo)}</FLAG_FYLO>
         <ID_GEO>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:idGeo)}</ID_GEO>
         <AXT_MAIN_DESC>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:axtMainDesc)}</AXT_MAIN_DESC>
         <ENARXI>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:enarxh)}</ENARXI>
         <DIAKOPI>{fn:data($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:diakoph)}</DIAKOPI>
         <anadoxoiIdGeoDescr>
          {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('Geo'),
                                      'select perigrafh from Kps6_c_geografia  where  id_geo = ?',
                                       xs:unsignedInt(tdy:if-empty($YpoAnadoxos/tdy-db:kpsAnadoxoi/tdy-db:idGeo,0)))//*:PERIGRAFH)}
         </anadoxoiIdGeoDescr>
        </KPS_ANADOXOI>
       </KPS6_YPOE_ANADOXOI>
       else <KPS6_YPOE_ANADOXOI/>
      }
      {if ($db-response//tdy-db:Kps6YpoeKatanomh/node()) then  
       for $Katanomi in $db-response//tdy-db:Kps6YpoeKatanomh return
       <KPS6_YPOE_KATANOMH>
        <YKA_ID>{fn:data($Katanomi/tdy-db:ykaId)}</YKA_ID>
        <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
        <ETOS>{fn:data($Katanomi/tdy-db:etos)}</ETOS>
        <POSO_DD_A>{fn:data($Katanomi/tdy-db:posoDdA)}</POSO_DD_A>
        <POSO_DD_EPIL_A>{fn:data($Katanomi/tdy-db:posoDdEpilA)}</POSO_DD_EPIL_A>
      </KPS6_YPOE_KATANOMH>
      else <KPS6_YPOE_KATANOMH/>
      }
      {if ($db-response//tdy-db:Kps6YpoeEpileksimes/node()) then  
       for $EpileksimiDapani in $db-response//tdy-db:Kps6YpoeEpileksimes return
        <KPS6_YPOE_EPILEKSIMES>
        <YEP_ID>{fn:data($EpileksimiDapani/tdy-db:yepId)}</YEP_ID>
        <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
        <ID_KATHGORIA_DAPANHS>{fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)}</ID_KATHGORIA_DAPANHS>
        <ID_XARAKTHRISTIKO_DAPANHS>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:idXarakthristikoDapanhs)}</ID_XARAKTHRISTIKO_DAPANHS>
        <POSO_DD_NOFPA>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:posoDdNofpa)}</POSO_DD_NOFPA>
        <POSO_FPA_DD>{fn:data($EpileksimiDapani/tdy-db:posoFpaDd)}</POSO_FPA_DD>
        <POSO_DD_EPIL>{fn:data($EpileksimiDapani/tdy-db:posoDdEpil)}</POSO_DD_EPIL>
        <POSO_FPA_EPILEKSIMH_DD>{fn:data($EpileksimiDapani/tdy-db:posoFpaEpileksimhDd)}</POSO_FPA_EPILEKSIMH_DD>
        <PERIGRAFH_KAT_DAPANHS>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:perigrafhKatDapanhs)}</PERIGRAFH_KAT_DAPANHS>
        <POSOSTO>{fn:data($EpileksimiDapani/tdy-db:pososto)}</POSOSTO>
        <KOSTOS_MONADAS>
          { if (fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)=(10,11)) then
              fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:monadiaioKostos)
            else fn:data($EpileksimiDapani/tdy-db:kostosMonadas)
          }
        </KOSTOS_MONADAS>
        <MONADA_METRHSHS>
          {if (fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)=(10,11)) then
            fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:monadaMetrhshs)
           else 
           fn:data($EpileksimiDapani/tdy-db:monadaMetrhshs)
          }
        </MONADA_METRHSHS>
        <PERIGRAFH_MONADAS>
          {if (fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)=(10,11)) then
            fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:perigrafhMonadas)
           else 
           fn:data($EpileksimiDapani/tdy-db:perigrafhMonadas)
          }
        </PERIGRAFH_MONADAS>
        <ARITHMOS_MONADON>
          {if (fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)=(10,11)) then
            fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:arithmosMonadon)
          else 
           fn:data($EpileksimiDapani/tdy-db:arithmosMonadon)
          }
        </ARITHMOS_MONADON>
        <AITIOLOGHSH_MH_EPILEKSIMOTHTAS>{fn:data($EpileksimiDapani/tdy-db:aitiologhshMhEpileksimothtas)}</AITIOLOGHSH_MH_EPILEKSIMOTHTAS>
        <ID_UNCO>{fn:data($EpileksimiDapani/tdy-db:idUnco)}</ID_UNCO>
        <ST_FLAG>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:stFlag)}</ST_FLAG>
        <KODIKOS_DAPANHS>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:kodikosDapanhs)}</KODIKOS_DAPANHS>
        <POSOTHTA_SYNOLIKH>
          {if (fn:data($EpileksimiDapani/tdy-db:idKathgoriaDapanhs)=(10,11)) then
            fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:posothtaSynolikh)
          else ()
          } 
        </POSOTHTA_SYNOLIKH>
        <ID_YPUNCO>{fn:data($EpileksimiDapani/tdy-db:idYpunco)}</ID_YPUNCO>    
        <FLAG_APLOPOIHMENO_KOSTOS>{fn:data($EpileksimiDapani//tdy-db:VsTdyEpileksimesInfo/tdy-db:flagAplopoihmenoKostos)}</FLAG_APLOPOIHMENO_KOSTOS>
       </KPS6_YPOE_EPILEKSIMES>
       else <KPS6_YPOE_EPILEKSIMES/>
      }      
      {if ($db-response//tdy-db:Kps6YpoeDeiktes/node()) then      
        for $Deikti in $db-response//tdy-db:Kps6YpoeDeiktes return
         <KPS6_YPOE_DEIKTES>
          <YDE_ID>{fn:data($Deikti/tdy-db:ydeId)}</YDE_ID>
          <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
          <KODIKOS_DEIKTHS>{fn:data($Deikti/tdy-db:kodikosDeikths)}</KODIKOS_DEIKTHS>
          <TIMH_STOXOS>{fn:data($Deikti/tdy-db:timhStoxos)}</TIMH_STOXOS>
         </KPS6_YPOE_DEIKTES> 
       else <KPS6_YPOE_DEIKTES/>        
      }      
      {if ($db-response//tdy-db:Kps6YpoeDiakrita/node()) then
       for $Diakrito in $db-response//tdy-db:Kps6YpoeDiakrita return
        <KPS6_YPOE_DIAKRITA>            
         <YDI_ID>{fn:data($Diakrito/tdy-db:ydiId)}</YDI_ID>
         <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
         <AA_DIAKRITOY>{fn:data($Diakrito/tdy-db:aaDiakritoy)}</AA_DIAKRITOY>
         <ONOMA_DIAKRITOY>{fn:data($Diakrito/tdy-db:onomaDiakritoy)}</ONOMA_DIAKRITOY>
         <PROYPOLOGISMOS>{fn:data($Diakrito/tdy-db:proypologismos)}</PROYPOLOGISMOS>
         <DATE_MILESTONE>{fn:data($Diakrito/tdy-db:dateMilestone)}</DATE_MILESTONE>
         <ENERGEIES_FAPE>{fn:data($Diakrito/tdy-db:energeiesFape)}</ENERGEIES_FAPE>
         <PARADOTEA_FAPE>{fn:data($Diakrito/tdy-db:paradoteaFape)}</PARADOTEA_FAPE>
         <PROYPOLOGISMOS_EPIL>{fn:data($Diakrito/tdy-db:proypologismosEpil)}</PROYPOLOGISMOS_EPIL>
         <DATE_START>{fn:data($Diakrito/tdy-db:dateStart)}</DATE_START>
        </KPS6_YPOE_DIAKRITA>
       else <KPS6_YPOE_DIAKRITA/>  
      }
      {if ($db-response//tdy-db:Kps6YpoeXorothethseis/node()) then  
       for $Xorothetisi in $db-response//tdy-db:Kps6YpoeXorothethseis return 
       <KPS6_YPOE_XOROTHETHSEIS>
        <YXO_ID>{fn:data($Xorothetisi/tdy-db:yxoId)}</YXO_ID>
        <TDY_ID>{fn:data($db-response//tdy-db:Kps6Ypoerga/tdy-db:tdyId)}</TDY_ID>
        <AA_XOROTHETHSHS>{fn:data($Xorothetisi/tdy-db:aaXorothethshs)}</AA_XOROTHETHSHS>
        <POSOSTO>{fn:data($Xorothetisi/tdy-db:pososto)}</POSOSTO>
        <ID_GEO>{fn:data($Xorothetisi/tdy-db:idGeo)}</ID_GEO>
        <ID_TK>{fn:data($Xorothetisi/tdy-db:idTk)}</ID_TK>
        <POSO>{fn:data($Xorothetisi/tdy-db:poso)}</POSO>
        <PER_NOM_DESCR>{fn:data($Xorothetisi/tdy-db:vsTdyXorothethseisInfo/tdy-db:perNomDescr)}</PER_NOM_DESCR>
       </KPS6_YPOE_XOROTHETHSEIS>
       else <KPS6_YPOE_XOROTHETHSEIS/>
      }
     </KPS6_YPOERGA> else ()}      
    </DATA>   
    {if ($db-response//tdy-db:Kps6Ypoerga/node()) then 
    (<actionCode/>,
    <comments/>,
    <combineChecks>1</combineChecks>)   
    else ()}
 </TDYGetResponse>
};

declare function tdy:map-insert-request-to-db($request as element()) 
 as element()(:: schema-element(tdy-db-update:Kps6YpoergaCollection) ::)
{
 let $EpilesimesDapanes := for $EpileksimiDapani in $request//tdy:KPS6_YPOE_EPILEKSIMES return
              <KPS6_YPOE_EPILEKSIMES>
              {$EpileksimiDapani/*:ID_YPUNCO/preceding-sibling::*}
              {if (fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Flag_Kostos',
                   'select flag_aplopoihmeno_kostos as Flag_Kostos  
                    from KPS6_EPILEKSIMES_DAPANES where ID_KATHGORIA_DAPANHS = ?',
                    xs:unsignedInt($EpileksimiDapani/*:ID_KATHGORIA_DAPANHS))//*:FLAG_KOSTOS)=(0,1) 
                    and fn:not($EpileksimiDapani/*:ID_YPUNCO/text()))
               then fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Id_Ypunco',
                    'Select ID_YPUNCO_SEQ.NEXTVAL from Dual')//*:NEXTVAL)
               else ()
              }
              {$EpileksimiDapani/*:ID_YPUNCO/following-sibling::*}
              </KPS6_YPOE_EPILEKSIMES>
  return              
  <tns:Kps6YpoergaCollection xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/db/top/TDYWriteService">
    <Kps6Ypoerga>
      <tdyId>{fn:data($request//*:KPS6_YPOERGA/*:TDY_ID)}</tdyId>
      <kodikosMis>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_MIS)}</kodikosMis>
      <kodikosYpoergoy>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
      <aaTdy>{fn:data($request//*:KPS6_YPOERGA/*:AA_TDY)}</aaTdy>
      <aaYpoekdosh>{fn:data($request//*:KPS6_YPOERGA/*:AA_YPOEKDOSH)}</aaYpoekdosh>
      <kathgoriaEkdoshs>{fn:data($request//*:KPS6_YPOERGA/*:KATHGORIA_EKDOSHS)}</kathgoriaEkdoshs>
      <titlosYpoergoy>{fn:data($request//*:KPS6_YPOERGA/*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <kodikosProeg>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_PROEG)}</kodikosProeg>
      <texnikhPerigrafh>{fn:data($request//*:KPS6_YPOERGA/*:TEXNIKH_PERIGRAFH)}</texnikhPerigrafh>
      <arProtokDa>{fn:data($request//*:KPS6_YPOERGA/*:AR_PROTOK_DA)}</arProtokDa>
      <dateYpovolis>{fn:data($request//*:KPS6_YPOERGA/*:DATE_YPOVOLIS)}</dateYpovolis>
      <dateEpileksimothtas>{fn:data($request//*:KPS6_YPOERGA/*:DATE_EPILEKSIMOTHTAS)}</dateEpileksimothtas>
      <dateAnalhpshs>{fn:data($request//*:KPS6_YPOERGA/*:DATE_ANALHPSHS)}</dateAnalhpshs>
      <dateLhkshs>{fn:data($request//*:KPS6_YPOERGA/*:DATE_LHKSHS)}</dateLhkshs>
      <dateTropop>{fn:data($request//*:KPS6_YPOERGA/*:DATE_TROPOP)}</dateTropop>
      <kodikosEpivlepoysas>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_EPIVLEPOYSAS)}</kodikosEpivlepoysas>
      <parathrhseisKataxorTdy>{fn:data($request//*:KPS6_YPOERGA/*:PARATHRHSEIS_KATAXOR_TDY)}</parathrhseisKataxorTdy>
      <parathrhseisKataxorTdyDik>{fn:data($request//*:KPS6_YPOERGA/*:PARATHRHSEIS_KATAXOR_TDY_DIK)}</parathrhseisKataxorTdyDik>
      <eidosAnatheshs>
       {if (fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Anathesis',
             'select count(PT.KODIKOS_DIAD_ANATHESHS) as ANATHESIS 
              from KPS6_PROEG_YPOERGA py 
              inner join KPS6_PROEG_TROPOP pt on PT.ID_PROEG = PY.ID_PROEG 
              where PY.KODIKOS_MIS = ?  
                and PY.KODIKOS_YPOERGOY = ?  
                and PT.ID_PROEG_TROPOP = (select max(id_proeg_tropop) 
                                          from KPS6_PROEG_TROPOP p1 
                                          where P1.ID_PROEG = PT.ID_PROEG)',
              xs:unsignedInt($request//*:KPS6_YPOERGA/*:KODIKOS_MIS),
              xs:unsignedInt($request//*:KPS6_YPOERGA/*:KODIKOS_MIS))//*:ANATHESIS)>1) then
       fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Diadikasia',
            'select PT.KODIKOS_DIAD_ANATHESHS 
             from KPS6_PROEG_YPOERGA py 
             inner join KPS6_PROEG_TROPOP pt on PT.ID_PROEG = PY.ID_PROEG 
             where PY.KODIKOS_MIS = ? 
               and PY.KODIKOS_YPOERGOY = ?
               and PT.ID_PROEG_TROPOP = (select max(id_proeg_tropop) 
                                         from KPS6_PROEG_TROPOP p1 
                                         where P1.ID_PROEG = PT.ID_PROEG)',
            xs:unsignedInt($request//*:KPS6_YPOERGA/*:KODIKOS_MIS),
            xs:unsignedInt($request//*:KPS6_YPOERGA/*:KODIKOS_MIS))//*:KODIKOS_DIAD_ANATHESHS)
                                         
       else
        fn:data($request//*:KPS6_YPOERGA/*:EIDOS_ANATHESHS)         
      }
      </eidosAnatheshs>
      <kodikosDikaioyxos>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_DIKAIOYXOS)}</kodikosDikaioyxos>
      <elegxosAatdp>{fn:data($request//*:KPS6_YPOERGA/*:ELEGXOS_AATDP)}</elegxosAatdp>
      <onomaYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:ONOMA_YPEYTHINOY)}</onomaYpeythinoy>
      <theshYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:THESH_YPEYTHINOY)}</theshYpeythinoy>
      <specialityYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:SPECIALITY_YPEYTHINOY)}</specialityYpeythinoy>
      <dieythynshYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:DIEYTHYNSH_YPEYTHINOY)}</dieythynshYpeythinoy>
      <thlYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:THL_YPEYTHINOY)}</thlYpeythinoy>
      <faxYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:FAX_YPEYTHINOY)}</faxYpeythinoy>
      <emailYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:EMAIL_YPEYTHINOY)}</emailYpeythinoy>
      <idTdySymplhromatikhs>{fn:data($request//*:KPS6_YPOERGA/*:ID_TDY_SYMPLHROMATIKHS)}</idTdySymplhromatikhs>
      <typosTdy>{fn:data($request//*:KPS6_YPOERGA/*:TYPOS_TDY)}</typosTdy>
      <aitiologiaYpoekdoshs>{fn:data($request//*:KPS6_YPOERGA/*:AITIOLOGIA_YPOEKDOSHS)}</aitiologiaYpoekdoshs>
      <flagTropTimetable>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_TIMETABLE)}</flagTropTimetable>
      <flagTropOik>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_OIK)}</flagTropOik>
      <flagTropFys>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_FYS)}</flagTropFys>
      <flagTropAllo>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_ALLO)}</flagTropAllo>
      <kodikosOikonomikhs>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_OIKONOMIKHS)}</kodikosOikonomikhs>
      <perigrafhOikonomikhs>{fn:data($request//*:KPS6_YPOERGA/*:PERIGRAFH_OIKONOMIKHS)}</perigrafhOikonomikhs>
      <onomaYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:ONOMA_YPEYTHINOY_OIK)}</onomaYpeythinoyOik>
      <theshYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:THESH_YPEYTHINOY_OIK)}</theshYpeythinoyOik>
      <dieythynshYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:DIEYTHYNSH_YPEYTHINOY_OIK)}</dieythynshYpeythinoyOik>
      <thlYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:THL_YPEYTHINOY_OIK)}</thlYpeythinoyOik>
      <emailYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:EMAIL_YPEYTHINOY_OIK)}</emailYpeythinoyOik>
      <posoMhEnisxyomenh>{fn:data($request//*:KPS6_YPOERGA/*:POSO_MH_ENISXYOMENH)}</posoMhEnisxyomenh>
      <posoIdiot>{fn:data($request//*:KPS6_YPOERGA/*:POSO_IDIOT)}</posoIdiot>
      <periorismoiMeep>
       {if (fn:data($request//*:KPS6_YPOERGA/*:PERIORISMOI_MEEP)) then 
        fn:data($request//*:KPS6_YPOERGA/*:PERIORISMOI_MEEP)
        else 65000
       }
      </periorismoiMeep>
      <dateMeep>{fn:data($request//*:KPS6_YPOERGA/*:DATE_MEEP)}</dateMeep>
      <perigrafhEpivlepousas>{fn:data($request//*:KPS6_YPOERGA/*:PERIGRAFH_EPIVLEPOYSAS)}</perigrafhEpivlepousas>
      <proelefshDeltio>{fn:data($request//*:KPS6_YPOERGA/*:PROELEYSH_DELTIO)}</proelefshDeltio>
      <daText>{fn:data($request//*:KPS6_YPOERGA/*:DA_TEXT)}</daText>
      <flagAytomatiEkgkrishTdy>
        {if ($request//*:KPS6_YPOERGA/*:FLAG_AYTOMATI_EKGKRISH_TDY/text()) 
         then  fn:data( $request//*:KPS6_YPOERGA/*:FLAG_AYTOMATI_EKGKRISH_TDY) 
         else  0 }
      </flagAytomatiEkgkrishTdy>
      <!--<flagEksairesiProe>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_EKSAIRESI_PROE)}</flagEksairesiProe>-->
      <kps6YpoergaMonadiaiaKosthCollection>
       {for $EpileksimiDapani in $EpilesimesDapanes where $EpileksimiDapani/node() return 
        if ($EpileksimiDapani/node() and 
             fn:not(fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Flag_Kostos',
                   'select flag_aplopoihmeno_kostos as Flag_Kostos  
                    from KPS6_EPILEKSIMES_DAPANES where ID_KATHGORIA_DAPANHS = ?',
                    xs:unsignedInt($EpileksimiDapani/*:ID_KATHGORIA_DAPANHS))//*:FLAG_KOSTOS)=(0,1)) )
        then
            <Kps6YpoergaMonadiaiaKosth>
              <idYpunco>{fn:data($EpileksimiDapani/*:ID_YPUNCO)}</idYpunco>
               <idUnco>
                {if ($EpileksimiDapani/*:ID_UNCO/text()) then  fn:data($EpileksimiDapani/*:ID_UNCO)  else  99 }
               </idUnco>
               <timhMonadas>{fn:data($EpileksimiDapani/*:KOSTOS_MONADAS)}</timhMonadas>
               <posothta>
                {if ($EpileksimiDapani/*:ARITHMOS_MONADON/text()) then  fn:data($EpileksimiDapani/*:ARITHMOS_MONADON)  else  1 }
                </posothta>
               <posothtaSynolikh>
                 {if ($EpileksimiDapani/*:APOSOTHTA_SYNOLIKH /text()) then  fn:data($EpileksimiDapani/*:POSOTHTA_SYNOLIKH)  else  1 }
               </posothtaSynolikh>
              </Kps6YpoergaMonadiaiaKosth>
        else ()
       }
     </kps6YpoergaMonadiaiaKosthCollection>     
     <kps6YpoeAnadoxoiCollection>
     {for $Anadoxos in  $request//*:KPS6_YPOE_ANADOXOI where $Anadoxos/node()  return         
       <Kps6YpoeAnadoxoi>
        <yanId>
          {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Id_Ypunco','Select YAN_ID_SEQ.NEXTVAL from Dual')//*:NEXTVAL)}
        </yanId>
        <afm>{fn:data($Anadoxos/*:AFM)}</afm>
        <adamSymvashs>{fn:data($Anadoxos/*:ADAM_SYMVASHS)}</adamSymvashs>
        <rolosAnadoxou>{fn:data($Anadoxos/*:ROLOS_ANADOXOU)}</rolosAnadoxou>
        <energosAnadoxos>{fn:data($Anadoxos/*:ENERGOS_ANADOXOS)}</energosAnadoxos>
        <aitiologiaAnenergoy>{fn:data($Anadoxos/*:AITIOLOGIA_ANENERGOY)}</aitiologiaAnenergoy>
        <posoDd>{fn:data($Anadoxos/*:POSO_DD)}</posoDd>
        <parathrhseisKataxorTdyAna>{fn:data($Anadoxos/*:PARATHRHSEIS_KATAXOR_TDY_ANA)}</parathrhseisKataxorTdyAna>
        <!--<dateSymbashs>{fn:data($Anadoxos/*:DATE_SYMBASHS)}</dateSymbashs>-->
      </Kps6YpoeAnadoxoi>
     }
     </kps6YpoeAnadoxoiCollection>
     <kps6YpoeDiakritaCollection>whee 
     {for $Diakrito in $request//*:KPS6_YPOE_DIAKRITA where $Diakrito/node() return
       <Kps6YpoeDiakrita>
          <ydiId>{fn:data($Diakrito/*:YDI_ID)}</ydiId>
          <aaDiakritoy>{fn:data($Diakrito/*:AA_DIAKRITOY)}</aaDiakritoy>
          <onomaDiakritoy>{fn:data($Diakrito/*:ONOMA_DIAKRITOY)}</onomaDiakritoy>
          <proypologismos>{fn:data($Diakrito/*:PROYPOLOGISMOS)}</proypologismos>
          <dateMilestone>{fn:data($Diakrito/*:DATE_MILESTONE)}</dateMilestone>
          <energeiesFape>{fn:data($Diakrito/*:ENERGEIES_FAPE)}</energeiesFape>
          <paradoteaFape>{fn:data($Diakrito/*:PARADOTEA_FAPE)}</paradoteaFape>
          <proypologismosEpil>{fn:data($Diakrito/*:PROYPOLOGISMOS_EPIL)}</proypologismosEpil>
          <dateStart>{fn:data($Diakrito/*:DATE_START)}</dateStart>
       </Kps6YpoeDiakrita>
     }
     </kps6YpoeDiakritaCollection>
     <kps6YpoeEpileksimesCollection>
      {for $Dapani in $EpilesimesDapanes where $Dapani/node() return
        <Kps6YpoeEpileksimes>
          <yepId>{fn:data($Dapani/*:YEP_ID)}</yepId>
          <posoDdNofpa>{fn:data($Dapani/*:POSO_DD_NOFPA)}</posoDdNofpa>
          <posoFpaDd>
            {if (fn:data($Dapani/*:POSO_FPA_DD)) then fn:data($Dapani/*:POSO_FPA_DD)  else  0 }
          </posoFpaDd>
          <posoDdEpil>{fn:data($Dapani/*:POSO_DD_EPIL)}</posoDdEpil>
          <idKathgoriaDapanhs>{fn:data($Dapani/*:ID_KATHGORIA_DAPANHS)}</idKathgoriaDapanhs>
          <posoFpaEpileksimhDd>
            {if (fn:data($Dapani/*:POSO_FPA_EPILEKSIMH_DD)) then  fn:data($Dapani/*:POSO_FPA_EPILEKSIMH_DD) else  0 }
          </posoFpaEpileksimhDd>
          <perigrafhKatDapanhs/>
          <pososto>{fn:data($Dapani/*:POSOSTO)}</pososto>
          <kostosMonadas>
           {if (fn:data($Dapani/*:ID_KATHGORIA_DAPANHS) != 10) then fn:data($Dapani/*:KOSTOS_MONADAS) else () }
           </kostosMonadas>
          <monadaMetrhshs>
           {if (fn:data($Dapani/*:ID_KATHGORIA_DAPANHS) != 10) then fn:data($Dapani/*:MONADA_METRHSHS) else () }
           </monadaMetrhshs>
          <perigrafhMonadas>
           {if (fn:data($Dapani/*:ID_KATHGORIA_DAPANHS) != 10) then fn:data($Dapani/*:PERIGRAFH_MONADAS) else ()}
           </perigrafhMonadas>
          <arithmosMonadon>
           {if (fn:data($Dapani/*:ID_KATHGORIA_DAPANHS) != 10) then  fn:data($Dapani/*:ARITHMOS_MONADON) else ()}
          </arithmosMonadon>
          <kathgMhEpileksimothtas/>
          <aitiologhshMhEpileksimothtas>{fn:data($Dapani/*:AITIOLOGHSH_MH_EPILEKSIMOTHTAS)}</aitiologhshMhEpileksimothtas>
          <idUnco>{fn:data($Dapani/*:ID_UNCO)}</idUnco>
          <idYpunco>{fn:data($Dapani/*:ID_YPUNCO)}</idYpunco>
        </Kps6YpoeEpileksimes>
      }
     </kps6YpoeEpileksimesCollection> 
     <kps6YpoeKatanomhCollection>
      {for $Katanomi in $request//*:KPS6_YPOE_KATANOMH where $Katanomi/node() return
       <Kps6YpoeKatanomh>
        <ykaId>{fn:data($Katanomi/*:YKA_ID)}</ykaId>
        <etos>{fn:data($Katanomi/*:ETOS)}</etos>
        <posoDdA>{fn:data($Katanomi/*:POSO_DD_A)}</posoDdA>
        <posoDdEpilA>{fn:data($Katanomi/*:POSO_DD_EPIL_A)}</posoDdEpilA>
       </Kps6YpoeKatanomh>
     }
     </kps6YpoeKatanomhCollection>
     <kps6YpoeXorothethseisCollection>
     {for $Xorothetisi in $request//*:KPS6_YPOE_XOROTHETHSEIS where $Xorothetisi/node() return
       <Kps6YpoeXorothethseis>
          <yxoId>{fn:data($Xorothetisi/*:YXO_ID)}</yxoId>
          <aaXorothethshs>{fn:data($Xorothetisi/*:AA_XOROTHETHSHS)}</aaXorothethshs>
          <poso/>
          <pososto>{fn:data($Xorothetisi/*:POSOSTO)}</pososto>
          <idTk>{fn:data($Xorothetisi/*:ID_TK)}</idTk>
          <idGeo>{fn:data($Xorothetisi/*:ID_GEO)}</idGeo>
       </Kps6YpoeXorothethseis>
     }
     </kps6YpoeXorothethseisCollection>
     <kps6YpoeDeiktesCollection>
      {for $Deiktis in $request//*:KPS6_YPOE_DEIKTES where $Deiktis/node() return
       <Kps6YpoeDeiktes>
          <ydeId>{fn:data($Deiktis/*:YDE_ID)}</ydeId>
          <kodikosDeikths>{fn:data($Deiktis/*:KODIKOS_DEIKTHS)}</kodikosDeikths>
          <timhStoxos>{fn:data($Deiktis/*:TIMH_STOXOS)}</timhStoxos>
       </Kps6YpoeDeiktes>
      }
     </kps6YpoeDeiktesCollection>
   </Kps6Ypoerga>    
  </tns:Kps6YpoergaCollection>
};

declare function tdy:map-update-request-to-db($request as element()) as element() (:: schema-element(tdy-db-update:Kps6YpoergaCollection) ::)
{let $EpilesimesDapanes := for $EpileksimiDapani in $request//*:KPS6_YPOE_EPILEKSIMES return
              <KPS6_YPOE_EPILEKSIMES>
              {$EpileksimiDapani/*:ID_YPUNCO/preceding-sibling::*}
              <ID_YPUNCO>
              {if (fn:not(fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Flag_Kostos',
                   'select flag_aplopoihmeno_kostos as Flag_Kostos  
                    from KPS6_EPILEKSIMES_DAPANES where ID_KATHGORIA_DAPANHS = ?',
                    xs:unsignedInt($EpileksimiDapani/*:ID_KATHGORIA_DAPANHS))//*:FLAG_KOSTOS)=(0,1)) 
                    and fn:not($EpileksimiDapani/*:ID_YPUNCO/text()))
               then fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Id_Ypunco',
                    'Select ID_YPUNCO_SEQ.NEXTVAL from Dual')//*:NEXTVAL)
               else fn:data($EpileksimiDapani/*:ID_YPUNCO)
              }
              </ID_YPUNCO>
              {$EpileksimiDapani/*:ID_YPUNCO/following-sibling::*}
              </KPS6_YPOE_EPILEKSIMES>
  return        
  <tns:Kps6YpoergaCollection xmlns:tns="http://xmlns.oracle.com/pcbpel/adapter/db/top/TDYWriteService">
    <Kps6Ypoerga>
      <tdyId>{fn:data($request//*:KPS6_YPOERGA/*:TDY_ID)}</tdyId>
      <kodikosMis>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_MIS)}</kodikosMis>
      <kodikosYpoergoy>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
      <aaTdy>{fn:data($request//*:KPS6_YPOERGA/*:AA_TDY)}</aaTdy>
      <aaYpoekdosh>{fn:data($request//*:KPS6_YPOERGA/*:AA_YPOEKDOSH)}</aaYpoekdosh>
      <kathgoriaEkdoshs>{fn:data($request//*:KPS6_YPOERGA/*:KATHGORIA_EKDOSHS)}</kathgoriaEkdoshs>
      <titlosYpoergoy>{fn:data($request//*:KPS6_YPOERGA/*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <kodikosProeg>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_PROEG)}</kodikosProeg>
      <texnikhPerigrafh>{fn:data($request//*:KPS6_YPOERGA/*:TEXNIKH_PERIGRAFH)}</texnikhPerigrafh>
      <arProtokDa>{fn:data($request//*:KPS6_YPOERGA/*:AR_PROTOK_DA)}</arProtokDa>
      <dateYpovolis>{fn:data($request//*:KPS6_YPOERGA/*:DATE_YPOVOLIS)}</dateYpovolis>
      <dateEpileksimothtas>{fn:data($request//*:KPS6_YPOERGA/*:DATE_EPILEKSIMOTHTAS)}</dateEpileksimothtas>
      <dateAnalhpshs>{fn:data($request//*:KPS6_YPOERGA/*:DATE_ANALHPSHS)}</dateAnalhpshs>
      <dateLhkshs>{fn:data($request//*:KPS6_YPOERGA/*:DATE_LHKSHS)}</dateLhkshs>
      <dateTropop>{fn:data($request//*:KPS6_YPOERGA/*:DATE_TROPOP)}</dateTropop>
      <kodikosEpivlepoysas>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_EPIVLEPOYSAS)}</kodikosEpivlepoysas>
      <parathrhseisKataxorTdy>{fn:data($request//*:KPS6_YPOERGA/*:PARATHRHSEIS_KATAXOR_TDY)}</parathrhseisKataxorTdy>
      <parathrhseisKataxorTdyDik>{fn:data($request//*:KPS6_YPOERGA/*:PARATHRHSEIS_KATAXOR_TDY_DIK)}</parathrhseisKataxorTdyDik>
      <eidosAnatheshs>{fn:data($request//*:KPS6_YPOERGA/*:EIDOS_ANATHESHS)}</eidosAnatheshs>
      <kodikosDikaioyxos>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_DIKAIOYXOS)}</kodikosDikaioyxos>
      <elegxosAatdp>{fn:data($request//*:KPS6_YPOERGA/*:ELEGXOS_AATDP)}</elegxosAatdp>
      <onomaYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:ONOMA_YPEYTHINOY)}</onomaYpeythinoy>
      <theshYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:THESH_YPEYTHINOY)}</theshYpeythinoy>
      <specialityYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:SPECIALITY_YPEYTHINOY)}</specialityYpeythinoy>
      <dieythynshYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:DIEYTHYNSH_YPEYTHINOY)}</dieythynshYpeythinoy>
      <thlYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:THL_YPEYTHINOY)}</thlYpeythinoy>
      <faxYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:FAX_YPEYTHINOY)}</faxYpeythinoy>
      <emailYpeythinoy>{fn:data($request//*:KPS6_YPOERGA/*:EMAIL_YPEYTHINOY)}</emailYpeythinoy>
      <idTdySymplhromatikhs>{fn:data($request//*:KPS6_YPOERGA/*:ID_TDY_SYMPLHROMATIKHS)}</idTdySymplhromatikhs>
      <typosTdy>{fn:data($request//*:KPS6_YPOERGA/*:TYPOS_TDY)}</typosTdy>
      <aitiologiaYpoekdoshs>{fn:data($request//*:KPS6_YPOERGA/*:AITIOLOGIA_YPOEKDOSHS)}</aitiologiaYpoekdoshs>
      <flagTropTimetable>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_TIMETABLE)}</flagTropTimetable>
      <flagTropOik>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_OIK)}</flagTropOik>
      <flagTropFys>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_FYS)}</flagTropFys>
      <flagTropAllo>{fn:data($request//*:KPS6_YPOERGA/*:FLAG_TROP_ALLO)}</flagTropAllo>
      <kodikosOikonomikhs>{fn:data($request//*:KPS6_YPOERGA/*:KODIKOS_OIKONOMIKHS)}</kodikosOikonomikhs>
      <perigrafhOikonomikhs>{fn:data($request//*:KPS6_YPOERGA/*:PERIGRAFH_OIKONOMIKHS)}</perigrafhOikonomikhs>
      <onomaYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:ONOMA_YPEYTHINOY_OIK)}</onomaYpeythinoyOik>
      <theshYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:THESH_YPEYTHINOY_OIK)}</theshYpeythinoyOik>
      <dieythynshYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:DIEYTHYNSH_YPEYTHINOY_OIK)}</dieythynshYpeythinoyOik>
      <thlYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:THL_YPEYTHINOY_OIK)}</thlYpeythinoyOik>
      <emailYpeythinoyOik>{fn:data($request//*:KPS6_YPOERGA/*:EMAIL_YPEYTHINOY_OIK)}</emailYpeythinoyOik>
      <posoMhEnisxyomenh>{fn:data($request//*:KPS6_YPOERGA/*:POSO_MH_ENISXYOMENH)}</posoMhEnisxyomenh>
      <posoIdiot>{fn:data($request//*:KPS6_YPOERGA/*:POSO_IDIOT)}</posoIdiot>
      <periorismoiMeep>{fn:data($request//*:KPS6_YPOERGA/*:PERIORISMOI_MEEP)}</periorismoiMeep>
      <dateMeep>{fn:data($request//*:KPS6_YPOERGA/*:DATE_MEEP)}</dateMeep>
      <perigrafhEpivlepousas>{fn:data($request//*:KPS6_YPOERGA/*:PERIGRAFH_EPIVLEPOYSAS)}</perigrafhEpivlepousas>
      <proelefshDeltio>{fn:data($request//*:KPS6_YPOERGA/*:PROELEYSH_DELTIO)}</proelefshDeltio>
      <daText>{fn:data($request//*:KPS6_YPOERGA/*:DA_TEXT)}</daText>
      <flagAytomatiEkgkrishTdy>
        {if ($request//*:KPS6_YPOERGA/*:FLAG_AYTOMATI_EKGKRISH_TDY/text()) 
         then  fn:data( $request//*:KPS6_YPOERGA/*:FLAG_AYTOMATI_EKGKRISH_TDY) 
         else  0 }
      </flagAytomatiEkgkrishTdy>      
       <kps6YpoergaMonadiaiaKosthCollection>
       {for $EpileksimiDapani in $EpilesimesDapanes where $EpileksimiDapani/node() return 
        if ($EpileksimiDapani/node() and 
             fn:not(fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Flag_Kostos',
                   'select flag_aplopoihmeno_kostos as Flag_Kostos  
                    from KPS6_EPILEKSIMES_DAPANES where ID_KATHGORIA_DAPANHS = ?',
                    xs:unsignedInt($EpileksimiDapani/*:ID_KATHGORIA_DAPANHS))//*:FLAG_KOSTOS)=(0,1)) )
        then
            <Kps6YpoergaMonadiaiaKosth>
              <idYpunco>{fn:data($EpileksimiDapani/*:ID_YPUNCO)}</idYpunco>
               <idUnco>
                {if ($EpileksimiDapani/*:ID_UNCO/text()) then  fn:data($EpileksimiDapani/*:ID_UNCO)  else  99 }
               </idUnco>
               <timhMonadas>{fn:data($EpileksimiDapani/*:KOSTOS_MONADAS)}</timhMonadas>
               <posothta>
                {if ($EpileksimiDapani/*:ARITHMOS_MONADON/text()) then  fn:data($EpileksimiDapani/*:ARITHMOS_MONADON)  else  1 }
                </posothta>
               <posothtaSynolikh>
                 {if ($EpileksimiDapani/*:POSOTHTA_SYNOLIKH/text()) then  fn:data($EpileksimiDapani/*:POSOTHTA_SYNOLIKH)  else  1 }
               </posothtaSynolikh>
              </Kps6YpoergaMonadiaiaKosth>
        else ()
       }
     </kps6YpoergaMonadiaiaKosthCollection> 
      <kps6YpoeAnadoxoiCollection>
     {for $Anadoxos in  $request//*:KPS6_YPOE_ANADOXOI where $Anadoxos/node() return
      let $ergoEES := fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Stoxos',
                'select KPS6_ERGORAMA_TDP.IS_RECORD_STOXOS_3(KPS6_CORE.GET_ISXYON_TDP(?)) Stoxos From Dual',
                xs:unsignedInt($request//*:KPS6_YPOERGA/*:KODIKOS_MIS))//*:STOXOS)
      let $ExistsAFM := fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Flag_Kostos',
                'select count(*) As cnt from kps6_ypoe_anadoxoi where tdy_id =? and AFM = ? ',
                xs:unsignedInt($request//*:KPS6_YPOERGA/*:TDY_ID),
                xs:string($Anadoxos/*:AFM))//*:CNT)               
     return
      if ((fn:not(fn:data($Anadoxos/*:YAN_ID)) and (($ergoEES=1 and $ExistsAFM= 0) or $ergoEES=0)) or 
           fn:data($Anadoxos/*:YAN_ID)>0 ) then      
       <Kps6YpoeAnadoxoi>
        <yanId>
          {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS','Id_Ypunco','Select YAN_ID_SEQ.NEXTVAL from Dual')//*:NEXTVAL)}
        </yanId>
        <afm>{fn:data($Anadoxos/*:AFM)}</afm>
        <adamSymvashs>{fn:data($Anadoxos/*:ADAM_SYMVASHS)}</adamSymvashs>
        <rolosAnadoxou>{fn:data($Anadoxos/*:ROLOS_ANADOXOU)}</rolosAnadoxou>
        <energosAnadoxos>{fn:data($Anadoxos/*:ENERGOS_ANADOXOS)}</energosAnadoxos>
        <aitiologiaAnenergoy>{fn:data($Anadoxos/*:AITIOLOGIA_ANENERGOY)}</aitiologiaAnenergoy>
        <posoDd>{fn:data($Anadoxos/*:POSO_DD)}</posoDd>
        <parathrhseisKataxorTdyAna>{fn:data($Anadoxos/*:PARATHRHSEIS_KATAXOR_TDY_ANA)}</parathrhseisKataxorTdyAna>        
      </Kps6YpoeAnadoxoi>
     else ()
     }
     </kps6YpoeAnadoxoiCollection>
     <kps6YpoeDiakritaCollection>
     {for $Diakrito in $request//*:KPS6_YPOE_DIAKRITA where $Diakrito/node() return
       <Kps6YpoeDiakrita>
          <ydiId>{fn:data($Diakrito/*:YDI_ID)}</ydiId>
          <aaDiakritoy>{fn:data($Diakrito/*:AA_DIAKRITOY)}</aaDiakritoy>
          <onomaDiakritoy>{fn:data($Diakrito/*:ONOMA_DIAKRITOY)}</onomaDiakritoy>
          <proypologismos>{fn:data($Diakrito/*:PROYPOLOGISMOS)}</proypologismos>
          <dateMilestone>{fn:data($Diakrito/*:DATE_MILESTONE)}</dateMilestone>
          <energeiesFape>{fn:data($Diakrito/*:ENERGEIES_FAPE)}</energeiesFape>
          <paradoteaFape>{fn:data($Diakrito/*:PARADOTEA_FAPE)}</paradoteaFape>
          <proypologismosEpil>{fn:data($Diakrito/*:PROYPOLOGISMOS_EPIL)}</proypologismosEpil>
          <dateStart>{fn:data($Diakrito/*:DATE_START)}</dateStart>
       </Kps6YpoeDiakrita>
     }
     </kps6YpoeDiakritaCollection> 
     <kps6YpoeEpileksimesCollection>
      {for $Dapani in $EpilesimesDapanes where $Dapani/node()return
        <Kps6YpoeEpileksimes>
          <yepId>{fn:data($Dapani/*:YEP_ID)}</yepId>
          <posoDdNofpa>{fn:data($Dapani/*:POSO_DD_NOFPA)}</posoDdNofpa>
          <posoFpaDd>
            {if (fn:data($Dapani/*:POSO_FPA_DD)) then fn:data($Dapani/*:POSO_FPA_DD)  else  0 }
          </posoFpaDd>
          <posoDdEpil>{fn:data($Dapani/*:POSO_DD_EPIL)}</posoDdEpil>
          <idKathgoriaDapanhs>{fn:data($Dapani/*:ID_KATHGORIA_DAPANHS)}</idKathgoriaDapanhs>
          <posoFpaEpileksimhDd>
            {if (fn:data($Dapani/*:POSO_FPA_EPILEKSIMH_DD)) then  fn:data($Dapani/*:POSO_FPA_EPILEKSIMH_DD) else  0 }
          </posoFpaEpileksimhDd>
          <perigrafhKatDapanhs/>
          <pososto>{fn:data($Dapani/*:POSOSTO)}</pososto>
          <kostosMonadas>{fn:data($Dapani/*:KOSTOS_MONADAS)}</kostosMonadas>
          <monadaMetrhshs>{fn:data($Dapani/*:MONADA_METRHSHS)}</monadaMetrhshs>
          <perigrafhMonadas>{fn:data($Dapani/*:PERIGRAFH_MONADAS)}</perigrafhMonadas>
          <arithmosMonadon>{fn:data($Dapani/*:ARITHMOS_MONADON)}</arithmosMonadon>
          <kathgMhEpileksimothtas/>
          <aitiologhshMhEpileksimothtas>{fn:data($Dapani/*:AITIOLOGHSH_MH_EPILEKSIMOTHTAS)}</aitiologhshMhEpileksimothtas>
          <idUnco>{fn:data($Dapani/*:ID_UNCO)}</idUnco>
          <idYpunco>{fn:data($Dapani/*:ID_YPUNCO)}</idYpunco>
        </Kps6YpoeEpileksimes>
      }
     </kps6YpoeEpileksimesCollection> 
     <kps6YpoeKatanomhCollection>
      {for $Katanomi in $request//*:KPS6_YPOE_KATANOMH where $Katanomi/node()return
       <Kps6YpoeKatanomh>
        <ykaId>{fn:data($Katanomi/*:YKA_ID)}</ykaId>
        <etos>{fn:data($Katanomi/*:ETOS)}</etos>
        <posoDdA>{fn:data($Katanomi/*:POSO_DD_A)}</posoDdA>
        <posoDdEpilA>{fn:data($Katanomi/*:POSO_DD_EPIL_A)}</posoDdEpilA>
       </Kps6YpoeKatanomh>
     }
     </kps6YpoeKatanomhCollection>
     <kps6YpoeXorothethseisCollection>
     {for $Xorothetisi in $request//*:KPS6_YPOE_XOROTHETHSEIS where $Xorothetisi/node() return
       <Kps6YpoeXorothethseis>
          <yxoId>{fn:data($Xorothetisi/*:YXO_ID)}</yxoId>
          <aaXorothethshs>{fn:data($Xorothetisi/*:AA_XOROTHETHSHS)}</aaXorothethshs>
          <poso/>
          <pososto>{fn:data($Xorothetisi/*:POSOSTO)}</pososto>
          <idTk>{fn:data($Xorothetisi/*:ID_TK)}</idTk>
          <idGeo>{fn:data($Xorothetisi/*:ID_GEO)}</idGeo>
       </Kps6YpoeXorothethseis>
     }
     </kps6YpoeXorothethseisCollection>
     <kps6YpoeDeiktesCollection>
      {for $Deiktis in $request//*:KPS6_YPOE_DEIKTES where $Deiktis/node() return
       <Kps6YpoeDeiktes>
          <ydeId>{fn:data($Deiktis/*:YDE_ID)}</ydeId>
          <kodikosDeikths>{fn:data($Deiktis/*:KODIKOS_DEIKTHS)}</kodikosDeikths>
          <timhStoxos>{fn:data($Deiktis/*:TIMH_STOXOS)}</timhStoxos>
       </Kps6YpoeDeiktes>
      }
     </kps6YpoeDeiktesCollection>
    </Kps6Ypoerga>
  </tns:Kps6YpoergaCollection>
};
