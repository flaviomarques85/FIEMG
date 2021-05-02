#Include "TOTVS.CH"
#Include "RESTFUL.CH"
  
WSRESTFUL WSRNATUR DESCRIPTION "Rest de resposta Naturezas do sistem"

    WSMETHOD GET DESCRIPTION "resposta para Naturezas do sistema "  WSSYNTAX "/WSRNATUR/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRNATUR

    Local lRet
    Local cRet
    Local cUsuario:= ""
    Local cBody   
    Local jReq    := JSonObject():New()
    Local jRes    := JSonObject():New()
    
    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    
    jReq:FromJson(cBody)
    //cUsuario := jReq['usuario']
    //lRet := PswSeek(cUsuario,.T.)

    jRes['Response'] := GetNatureza()
    cRet := jRes:ToJson()
    ::SetResponse( EncodeUTF8(cRet))
    
return(.T.) 


static Function GetNatureza()
    
    Local jNatureza
    Local cQuery  := ""
    Local cAliasQry := GetNextAlias()
    Local aRet := {}
    Local cTipoNat := ""

    cQuery := " SELECT ED_FILIAL, ED_CODIGO, ED_DESCRIC, ED_COND  "
    cQuery += " FROM  "+RetSqlName("SED")+" as SED "
    cQuery += " WHERE SED.D_E_L_E_T_ <> '*' "
    cQuery += " AND ED_FILIAL = '"+ xFilial('SED') +"' "
    cQuery += " AND ED_MSBLQL <> '1' "
    
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry)

    While (cAliasQry)->(!Eof())
        jNatureza:= JsonObject():New()
        jNatureza['Filial'] := AllTrim((cAliasQry)->ED_FILIAL)
        jNatureza['Codigo'] := AllTrim((cAliasQry)->ED_CODIGO)
        jNatureza['Nome']   := AllTrim((cAliasQry)->ED_DESCRIC)
        IF (AllTrim((cAliasQry)->ED_COND)) == 'D'
            cTipoNat := 'Despesa'
         elseIf (AllTrim((cAliasQry)->ED_COND)) == 'R'
            cTipoNat := 'Receita'
        EndIf
        jNatureza['Tipo']   := cTipoNat
        AADD(aRet,jNatureza)
        (cAliasQry)->(dbSkip())
        FreeObj(jNatureza)
    EndDo
    (cAliasQry)->(dbCloseArea())

Return (aRet)




