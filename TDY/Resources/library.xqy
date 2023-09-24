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
               xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="aaaYpoekdosh"]/@value))//*:CNT_MEEP_NOT_NULL)
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
                 xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value))
   return
    if (fn:not($ListaYpoergon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Ypoergo in $ListaYpoergon return 
    <Ypoergo>
      <aaYpoergoy>{fn:data($Ypoergo//*:AA_YPOERGOY)}</aaYpoergoy>
      <titlosYpoergoy>{fn:data($Ypoergo//*:TITLOS_YPOERGOY)}</titlosYpoergoy>
      <kodikosYpoergoy>{fn:data($Ypoergo//*:KODIKOS_YPOERGOY)}</kodikosYpoergoy>
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
      <id_kathgoria_dapanhs>{fn:data($KatigoriaDapanis//*:ID_KATHGORIA_DAPANHS)}</id_kathgoria_dapanhs>
      <kodikos_dapanhs>{fn:data($KatigoriaDapanis//*:KODIKOS_DAPANHS)}</kodikos_dapanhs>
      <perigrafh_kathgoria_dapanhs>{fn:data($KatigoriaDapanis//*:PERIGRAFH_KATHGORIA_DAPANHS)}</perigrafh_kathgoria_dapanhs>
      <pososto>{fn:data($KatigoriaDapanis//*:POSOSTO)}</pososto>
      <id_unco>{fn:data($KatigoriaDapanis//*:ID_UNCO)}</id_unco>
      <monadiaio_kostos>{fn:data($KatigoriaDapanis//*:MONADIAIO_KOSTOS)}</monadiaio_kostos>
      <monada_metrhshs>{fn:data($KatigoriaDapanis//*:MONADA_METRHSHS)}</monada_metrhshs>
      <perigrafh_monadas>{fn:data($KatigoriaDapanis//*:PERIGRAFH_MONADAS)}</perigrafh_monadas>
      <oroi_efarmoghs>{fn:data($KatigoriaDapanis//*:OROI_EFARMOGHS)}</oroi_efarmoghs>
      <mis>{fn:data($KatigoriaDapanis//*:MIS)}</mis>
      <id_xar>{fn:data($KatigoriaDapanis//*:ID_XAR)}</id_xar>
    </KatigoriaDapanis>
  }
  </ListaKatigorionDapanis>
};

declare function tdy:GetAplopoimenoKostos($inbound as element()) as element(){
<ListaKatigorionDapanis xmlns="http://espa.gr/v6/tdy">
  {let $ListaKatigorionDapanis := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('KatigoriaDapanis'),
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
                xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="mis"]/@value))
   return
    if (fn:not($ListaKatigorionDapanis/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $KatigoriaDapanis in $ListaKatigorionDapanis return 
    <KatigoriaDapanis>
      <id>{fn:data($KatigoriaDapanis//*:ID)}</id>
      <kodikosDapanhs>{fn:data($KatigoriaDapanis//*:KODIKOS_DAPANHS)}</kodikosDapanhs>
      <perigrafh>{fn:data($KatigoriaDapanis//*:PERIGRAFH)}</perigrafh>
      <flagYpoergo>{fn:data($KatigoriaDapanis//*:FLAG_YPOERGO)}</flagYpoergo>
      <eidosDapanhs>{fn:data($KatigoriaDapanis//*:EIDOS_DAPANHS)}</eidosDapanhs>
      <xarakthristikoDapanhs>{fn:data($KatigoriaDapanis//*:XARAKTHRISTIKO_DAPANHS)}</xarakthristikoDapanhs>
      <plafon>{fn:data($KatigoriaDapanis//*:PLAFON)}</plafon>
      <flagPerigrafh>{fn:data($KatigoriaDapanis//*:FLAG_PERIGRAFH)}</flagPerigrafh>
      <flagAplopoiimenoKostos>{fn:data($KatigoriaDapanis//*:FLAG_APLOPOIHMENO_KOSTOS)}</flagAplopoiimenoKostos>
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
      <is_active>{fn:data($Timi//*:IS_ACTIVE)}</is_active>
    </Timi>
  }
  </ListaTimon>
};

declare function tdy:GetTitloYpoergoy($inbound as element()) as element(){
  <TitlosYpoergoy xmlns="http://espa.gr/v6/tdy">
    <title>
      {fn:data(fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('title'),
              'select titlos_ypoergoy 
              from kps6_tdp_ypoerga a  
               where a.kodikos_mis = ? 
                 and a.id_tdp in (select KPS6_core.get_max_aa(?,101) from dual) 
                 and a.kodikos_ypoergoy=?',
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosMis"]/@value),
              xs:unsignedInt($inbound/ctx:transport/ctx:request/tp:user-metadata[@name="kodikosYpoergoy"]/@value))//*:TITLOS_YPOERGOY)
      }
    </title>
  </TitlosYpoergoy>
};

declare function tdy:GetProsklisis() as element(){
<ListaProskliseon xmlns="http://espa.gr/v6/tdy">
  {let $Listaproskliseon := fn-bea:execute-sql('jdbc/mis_master6DS',xs:QName('YPOERGO'),
               'select distinct kodikos_proskl_forea, id_prosklhshs, kodikos_prosklhshs, titlos, titlos_en from
                kps6_prosklhseis')
   return
    if (fn:not($Listaproskliseon/node())) then
      fn:error(QName('urn:espa:v6:library:error','error'),'empty list')
    else 
   for $Prosklisi in $Listaproskliseon return 
    <Prosklisi>
      <dateTo/>
      <ekdosh/>
      <epKodikos/>
      <flagMicrodata>0</flagMicrodata>
      <foreasKodikos/>
      <idProsklhshs>{fn:data($Prosklisi//*:ID_PROSKLHSHS)}</idProsklhshs>
      <kodikosProsklForea>{fn:data($Prosklisi//*:KODIKOS_PROSKL_FOREA)}</kodikosProsklForea>
      <kodikosProsklhshs>{fn:data($Prosklisi//*:KODIKOS_PROSKLHSHS)}</kodikosProsklhshs>
      <metroKodikos/>
      <perigrafhForeaProsklhshs/>
      <titlos>{fn:data($Prosklisi//*:TITLOS)}</titlos>
      <userPermissionsMap/>
      <ypoprKodikos/>
    </Prosklisi>
  }
  </ListaProskliseon>
};