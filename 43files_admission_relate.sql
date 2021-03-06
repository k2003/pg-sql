select 
            b_site.b_visit_office_id as HOSPCODE
            , t_health_family.health_family_hn_hcis as PID 
            , t_visit.visit_vn as SEQ  
            , t_visit.visit_vn as AN
            , rpad(substr(t_visit.visit_begin_admit_date_time,1,4)::int -543
                                                ||replace(replace(replace(substr(t_visit.visit_begin_admit_date_time,5),'-',''),',',''),':',''),14,'0') as DATETIME_ADMIT 
            , case when  b_report_12files_map_clinic.b_report_12files_std_clinic_id in ('1300','1301','1302','1303','1304','1305')
                        then (t_visit.f_visit_type_id || b_report_12files_map_clinic.b_report_12files_std_clinic_id )
                     when  b_report_12files_map_clinic.b_report_12files_std_clinic_id not in ('1300','1301','1302','1303','1304','1305')
                        then (t_visit.f_visit_type_id || b_report_12files_map_clinic.b_report_12files_std_clinic_id || '00' )
                    else '00000' end as WARDADMIT
            , r_rp1855_instype.id as INSTYPE

            , t_visit.f_visit_service_type_id as TYPEIN

            , max(case when t_visit_refer_in_out.f_visit_refer_type_id = '0' 
                            then t_visit_refer_in_out.visit_refer_in_out_refer_hospital 
                            else '' end) as REFERINHOSP
            , max(case when t_visit_refer_in_out.f_visit_refer_type_id = '0' and t_visit.f_refer_cause_id in ('2','3','4','5','6') then '1'  
                        when t_visit_refer_in_out.f_visit_refer_type_id = '0' and t_visit.f_refer_cause_id in ('1') then '2'
                         when t_visit_refer_in_out.f_visit_refer_type_id = '0' and t_visit.f_refer_cause_id in ('7','8') then '5'
                        else '' end) as CAUSEIN
            , case when t_visit_vital_sign.visit_vital_sign_weight = '' or t_visit_vital_sign.visit_vital_sign_weight is null
                            then 0
                            else cast(t_visit_vital_sign.visit_vital_sign_weight as decimal(8,1)) end as ADMITWEIGHT
            , case when t_visit_vital_sign.visit_vital_sign_height = '' or t_visit_vital_sign.visit_vital_sign_height is null
                            then 0
                            else t_visit_vital_sign.visit_vital_sign_height::decimal(8,0) end as ADMITHEIGHT 
            , rpad(substr(t_visit.visit_staff_doctor_discharge_date_time,1,4)::int -543
                                                ||replace(replace(replace(substr(t_visit.visit_staff_doctor_discharge_date_time,5),'-',''),',',''),':',''),14,'0') as DATETIME_DISCH
            , case when  b_report_12files_map_clinic.b_report_12files_std_clinic_id in ('1300','1301','1302','1303','1304','1305')
                        then (t_visit.f_visit_type_id || b_report_12files_map_clinic.b_report_12files_std_clinic_id )
                     when  b_report_12files_map_clinic.b_report_12files_std_clinic_id not in ('1300','1301','1302','1303','1304','1305')
                        then (t_visit.f_visit_type_id || b_report_12files_map_clinic.b_report_12files_std_clinic_id || '00' )
                    else '00000' end as WARDDISCH
            , t_visit.f_visit_ipd_discharge_status_id as DISCHSTATUS
            , t_visit.f_visit_ipd_discharge_type_id as DISCHTYPE
            , max(case when t_visit_refer_in_out.f_visit_refer_type_id = '1' 
                            then t_visit_refer_in_out.visit_refer_in_out_refer_hospital 
                            else '' end) as REFEROUTHOSP
            , max(case when t_visit_refer_in_out.f_visit_refer_type_id = '1' and t_visit.f_refer_cause_id in ('2','3','4','5','6') then '1'  
                        when t_visit_refer_in_out.f_visit_refer_type_id = '1' and t_visit.f_refer_cause_id in ('1') then '2'
                         when t_visit_refer_in_out.f_visit_refer_type_id = '1' and t_visit.f_refer_cause_id in ('7','8') then '5'
                        else '' end) as CAUSEOUT
            , case when sum_order.order_cost is not null
                            then sum_order.order_cost::decimal(8,2)
                            else 0
                            end  as COST
            , case when billing.billing_total is not null 
                            then billing.billing_total::decimal(8,2)
                            else 0
                            end as PRICE
            , case when billing.billing_patient_share is not null 
                            then billing.billing_patient_share::decimal(8,2)
                            else 0
                            end as PAYPRICE
            , case when billing.billing_paid is not null 
                            then billing.billing_paid::decimal(8,2)
                            else 0
                            end as ACTUALPAY
            , b_employee.provider as PROVIDER
            , rpad(substr(t_visit.visit_staff_doctor_discharge_date_time,1,4)::int -543
                                                ||replace(replace(replace(substr(t_visit.visit_staff_doctor_discharge_date_time,5),'-',''),',',''),':',''),14,'0') as D_UPDATE  
from 
        t_visit inner join t_patient on t_visit.t_patient_id = t_patient.t_patient_id   
        inner join t_health_family on t_health_family.t_health_family_id = t_patient.t_health_family_id
        left join t_visit_vital_sign
                                            inner join (select 
                                                    t_visit_vital_sign.t_visit_id as t_visit_id
                                                    ,max(t_visit_vital_sign.record_date||','||t_visit_vital_sign.record_time) as vital_sign_record
                                            from t_visit_vital_sign inner join t_visit on t_visit_vital_sign.t_visit_id = t_visit.t_visit_id
                                            where t_visit_vital_sign.visit_vital_sign_active = '1'
                                                                and t_visit.f_visit_status_id ='3'
                                                                and t_visit.visit_money_discharge_status ='1'
                                                                and t_visit.visit_doctor_discharge_status ='1'
                                                               and substr(t_visit.visit_staff_doctor_discharge_date_time,1,10) between ':startDate' and ':endDate' 
                                                                and t_visit.f_visit_type_id = '1'
                                            group by t_visit_vital_sign.t_visit_id) as max_vital_sign
                                                         on t_visit_vital_sign.t_visit_id = max_vital_sign.t_visit_id
                                                                and (t_visit_vital_sign.record_date||','||t_visit_vital_sign.record_time) = max_vital_sign.vital_sign_record 
                     on t_visit.t_visit_id = t_visit_vital_sign.t_visit_id
        left join t_visit_payment on t_visit.t_visit_id = t_visit_payment.t_visit_id 
                                            and t_visit_payment.visit_payment_priority = '0' 
                                            and t_visit_payment.visit_payment_active = '1'
        left join 
                    (select 
                                t_billing.t_visit_id
                                , sum(t_billing.billing_total) as billing_total
                                , sum(t_billing.billing_patient_share) as billing_patient_share
                                , sum(t_billing.billing_paid) as billing_paid
                    from t_billing inner join t_visit on t_billing.t_visit_id = t_visit.t_visit_id
                    where t_billing.billing_active = '1' 
                                and t_visit.f_visit_status_id ='3'
                                and t_visit.visit_money_discharge_status ='1'
                                and t_visit.visit_doctor_discharge_status ='1'
                                and substr(t_visit.visit_staff_doctor_discharge_date_time,1,10) between ':startDate' and ':endDate' 
                                and t_visit.f_visit_type_id = '1'
                    group by
                             t_billing.t_visit_id ) as billing
                    on t_visit.t_visit_id = billing.t_visit_id 
        left join 
                    (select
                            t_order.t_visit_id
                            ,sum(case when t_order.order_cost = '' 
                                                then 0 
                                                else t_order.order_cost::numeric end *t_order.order_qty) as order_cost
                            ,sum(ceil(t_order.order_price*t_order.order_qty))  as order_price
                    from t_order inner join t_visit on t_order.t_visit_id = t_visit.t_visit_id
                    where t_order.f_order_status_id not in ('0','3')
                                and t_visit.f_visit_status_id ='3'
                                and t_visit.visit_money_discharge_status ='1'
                                and t_visit.visit_doctor_discharge_status ='1'
                                and substr(t_visit.visit_staff_doctor_discharge_date_time,1,10) between ':startDate' and ':endDate' 
                                and t_visit.f_visit_type_id = '1'
                    group by
                            t_order.t_visit_id) as sum_order
                    on t_visit.t_visit_id = sum_order.t_visit_id
        left join t_visit_refer_in_out on t_visit.t_visit_id = t_visit_refer_in_out.t_visit_id 
                                                and t_visit_refer_in_out.visit_refer_in_out_active ='1'
        left join b_report_12files_map_clinic  on t_visit.b_visit_clinic_id = b_report_12files_map_clinic.b_visit_clinic_id
        left join b_contract_plans on  t_visit_payment.b_contract_plans_id = b_contract_plans.b_contract_plans_id
        left join b_map_rp1855_instype on b_contract_plans.b_contract_plans_id = b_map_rp1855_instype.b_contract_plans_id
        left join r_rp1855_instype on b_map_rp1855_instype.r_rp1855_instype_id = r_rp1855_instype.id 
        left join b_employee on t_visit.visit_staff_doctor_discharge = b_employee.b_employee_id
        
        left join t_death on t_health_family.t_health_family_id = t_death.t_health_family_id
                                    and t_death.death_active = '1'
        cross join b_site

where
        t_health_family.health_family_active = '1'
        and t_visit.f_visit_status_id ='3'
        and t_visit.visit_money_discharge_status ='1'
        and t_visit.visit_doctor_discharge_status ='1'
        and b_site.b_visit_office_id||'|'||t_visit.visit_vn in (:in_pk)
        and b_site.b_visit_office_id||'|'||t_visit.visit_vn not in (:notin_pk)
        and t_visit.f_visit_type_id = '1'

        and (case when t_death.t_death_id is not null 
                    then true 
               when t_death.t_death_id is null and t_health_family.f_patient_discharge_status_id <> '1'
                    then true 
                    else false end)
group by
        HOSPCODE 
        ,PID  
        ,SEQ  
        ,AN
        ,DATETIME_ADMIT
        ,WARDADMIT
        ,INSTYPE
        ,TYPEIN

        ,ADMITWEIGHT
        ,ADMITHEIGHT
        ,DATETIME_DISCH
        ,WARDDISCH
        ,DISCHSTATUS
        ,DISCHTYPE

        ,COST
        ,PRICE
        ,PAYPRICE
        ,ACTUALPAY
        ,PROVIDER
        ,D_UPDATE

order by t_visit.visit_vn asc