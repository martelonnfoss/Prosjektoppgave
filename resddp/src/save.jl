function save!(RT::Result, SP_FORW,AMData,H2Data,InflowSys,NArea,NHSys,NK,NLine,s,t)
    for iSys = 1:NHSys
        for k = 1:NK
            RT.ReservoirTable[iSys,s,t,k] = JuMP.value(SP_FORW[:res][iSys,k])
            RT.SpillTable[iSys,s,t,k] = JuMP.value(SP_FORW[:spi][iSys,k])
            RT.HProdTable[iSys,s,t,k] = JuMP.value(SP_FORW[:prod][iSys,k])
        end
        RT.HRampTable[iSys,s,t] = JuMP.value(SP_FORW[:ramp][iSys])
        RT.HCapTable[iSys,s,t] = JuMP.value(SP_FORW[:cap][iSys])
        RT.InflowTable[iSys,s,t] = InflowSys[iSys]
    end
    for iArea = 1:NArea
        for k = 1:NK
            if AMData[iArea].NMStep > 0
                for iMark = 1:AMData[iArea].NMStep
                    RT.MarkTable[iArea,iMark,s,t,k] = JuMP.value(SP_FORW[:mark][iArea,iMark,k])
                end
            end
            RT.PriceTable[iArea,s,t,k] = -JuMP.shadow_price(SP_FORW[:pbal][iArea,k])
            RT.LoadTable[iArea,s,t,k] = JuMP.normalized_rhs(SP_FORW[:pbal][iArea,k]) + (JuMP.haskey(SP_FORW, :dr_tot) ? JuMP.value(SP_FORW[:dr_tot][iArea,k]) : 0)

            RT.RationingTable[iArea,s,t,k] = JuMP.value(SP_FORW[:rat][iArea,k])
            RT.WindTable[iArea,s,t,k] = JuMP.value(SP_FORW[:wprod][iArea,k])
            RT.DemandUpTable[iArea,s,t,k] = JuMP.haskey(SP_FORW, :dr_up) ?  JuMP.value(SP_FORW[:dr_up][iArea,k]) : 0
            RT.DemandDnTable[iArea,s,t,k] = JuMP.haskey(SP_FORW, :dr_dn) ? (JuMP.value(SP_FORW[:dr_up][iArea,k]) - JuMP.value(SP_FORW[:dr_tot][iArea,k])) : 0
        end
        if H2Data.Ind[iArea] > 0
            for k = 1:NK
                RT.H2StoreTable[iArea,s,t,k] = JuMP.value(SP_FORW[:h2res][H2Data.Ind[iArea],k])
                RT.H2DisTable[iArea,s,t,k] = -(1.0-H2Data.Areas[H2Data.Ind[iArea]].CompLoss)*JuMP.value(SP_FORW[:h2chg][H2Data.Ind[iArea],k])+JuMP.value(SP_FORW[:h2dis][H2Data.Ind[iArea],k])
            end
        end
    end
    for iLine = 1:NLine
        for k = 1:NK
            RT.FlowTable[iLine,s,t,k] = sum(JuMP.value(SP_FORW[:etran][iLine,k]))
        end
    end
end

function save_detailed!(DRT::DetailedResult, SP_FORW,AMData,AHData,NArea,NK,NLine,s,t)
    for iArea = 1:NArea
        for iMod = 1:AHData[iArea].NMod
            for k = 1:NK
                DRT.ReservoirTable[iArea,iMod,s,t,k] = JuMP.value(SP_FORW[:res][iArea,iMod,k])
                DRT.DischargeTable[iArea,iMod,s,t,k] = JuMP.value(SP_FORW[:dis][iArea,iMod,k])
                DRT.SpillTable[iArea,iMod,s,t,k] = JuMP.value(SP_FORW[:spi][iArea,iMod,k])
                DRT.BypassTable[iArea,iMod,s,t,k] = JuMP.value(SP_FORW[:byp][iArea,iMod,k])
                DRT.HProdTable[iArea,iMod,s,t,k] = JuMP.value(SP_FORW[:ghy][iArea,iMod,k])
            end
        end
    end
    for iArea = 1:NArea
        for k = 1:NK
            if AMData[iArea].NMStep > 0
                for iMark = 1:AMData[iArea].NMStep
                    DRT.MarkTable[iArea,iMark,s,t,k] = JuMP.value(SP_FORW[:mark][iArea,iMark,k])
                end
            end
            DRT.PriceTable[iArea,s,t,k] = -JuMP.shadow_price(SP_FORW[:pbal][iArea,k])
            DRT.LoadTable[iArea,s,t,k] = JuMP.normalized_rhs(SP_FORW[:pbal][iArea,k]) + (JuMP.haskey(SP_FORW, :dr_tot) ? JuMP.value(SP_FORW[:dr_tot][iArea,k]) : 0)

            DRT.RationingTable[iArea,s,t,k] = JuMP.value(SP_FORW[:rat][iArea,k])
            DRT.WindTable[iArea,s,t,k] = JuMP.value(SP_FORW[:wprod][iArea,k])
            DRT.DemandUpTable[iArea,s,t,k] = JuMP.haskey(SP_FORW, :dr_up) ?  JuMP.value(SP_FORW[:dr_up][iArea,k]) : 0
            DRT.DemandDnTable[iArea,s,t,k] = JuMP.haskey(SP_FORW, :dr_dn) ?  (JuMP.value(SP_FORW[:dr_up][iArea,k]) - JuMP.value(SP_FORW[:dr_tot][iArea,k])) : 0
        end
    end
    for iLine = 1:NLine
        for k = 1:NK
            DRT.FlowTable[iLine,s,t,k] = sum(JuMP.value(SP_FORW[:etran][iLine,k]))
        end
    end
end
