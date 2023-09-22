xquery version "1.0" encoding "utf-8";

(:: OracleAnnotationVersion "1.0" ::)

module namespace tdy="http://espa.gr/v6/tdy/library";

(: Δηλώσεις namespaces OSB  :)
declare namespace ctx="http://www.bea.com/wli/sb/context";
declare namespace http="http://www.bea.com/wli/sb/transports/http";
declare namespace tp="http://www.bea.com/wli/sb/transports";
declare namespace dvm="http://www.oracle.com/osb/xpath-functions/dvm";
declare namespace soap-env="http://schemas.xmlsoap.org/soap/envelope";
declare namespace error="urn:espa:v6:library:error";

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
  {let $ListaVersion := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
 
 let $ListaYpoergon:= fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
 {for $Ypoergo in fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
   <Ypoergo>      
      <aaYpoergoy>{fn:data($Ypoergo//*:AAYPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOSYPOERGOY)}</titlosYpoergoy>
      <tdyId>{fn:data($Ypoergo//*:IDDELTIOY)}</tdyId>      
      <neaEkdosh>{fn:data($Ypoergo//*:EKDOSH)}</neaEkdosh>>      
      <kodikosYpoergoy>{fn:data($Ypoergo//*:KODIKOSYPOERGOY)}</kodikosYpoergoy>
    </Ypoergo>   
 }   
 </ListYpoergon>
};

declare function tdy:GetElegxoiNomimotitasList($inbound as element()) as element(){

 <ListElegxonNomimotitas xmlns="http://espa.gr/v6/tdy">
 { let $ListaElegxnonNomimotitas := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
                 else ?
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
                 else ?
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
	        and obj_status_id != 309 ',
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
      <ElegxosNomimotita>
       <aaProegrisis>{fn:data($Elegxos//*:PROEG_AA)}</aaProegrisis>
       <titlos>{fn:data($Elegxos//*:TITLOS)}</titlos>
       <aa>{fn:data($Elegxos//*:AA)}</aa>
       <idProegTropop>{fn:data($Elegxos//*:ID_PROEG_TROPOP)}</idProegTropop>
      </ElegxosNomimotita>
 }
 </ListElegxonNomimotitas>
};

declare function tdy:GetMeepCount($inbound as element()) as element(){
  <MeepCount xmlns="http://espa.gr/v6/tdy">
   {xs:unsignedShort(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
   {xs:unsignedShort(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
               'select count(*) as cnt_meep_not_null
                from kps6_ypoerga y
                where y.kodikos_ypoergoy = ?
                and (y.aa_tdy != ? OR  (y.aa_tdy = ? AND  y.aa_ypoekdosh != ?))
                and nvl(PERIORISMOI_MEEP,65000) != 65000',
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaTdy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaTdy"]/@value),
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaaYpoekdosh"]/@value))//*:CNT_MEEP_NOT_NULL)
  }
  </MeepCount>
};

declare function tdy:GetGeoList($inbound as element()) as element(){
 <GeoList xmlns="http://espa.gr/v6/tdy">
 { let $ListaGeo := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('SQL-RESULT'),
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
    <labelPerifereiaNomos/>
    <idGeo>{fn:data($GeoItem//*:ID_GEO)}</idGeo>
    <idCountry/>
    <idKratid/>
    <idPerif>{fn:data($GeoItem//*:ID_PERIF)}</idPerif>
    <idNomos>{fn:data($GeoItem//*:ID_NOMOS)}</idNomos>
    <idDhmos>{fn:data($GeoItem//*:ID_NOMOS)}</idDhmos>
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


