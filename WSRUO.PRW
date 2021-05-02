#Include "TOTVS.CH"
#Include "RESTFUL.CH"

/*  
WSRESTFUL WSRUO DESCRIPTION "Rest de resposta Naturezas do sistem"

    WSMETHOD GET DESCRIPTION "resposta para Filiais do Naturezas"  WSSYNTAX "/WSRUO/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRUO
*/
USER FUNCTION TESTEWSR(cDados)
    Local lRet
    Local cUsuario
    Local cBody   := cDados
    Local jReq    := JSonObject():New()
    Local jRes    := JSonObject():New()
    
    //::SetContentType("application/json")  
    //cBody  := ::GetContent()
    
    jReq:FromJson(cBody)
    //cUsuario := jReq['usuario']
    //lRet := PswSeek(cUsuario,.T.)

    jRes['Response'] := GetCtt()
    cRet := jRes:ToJson()
    ::SetResponse(EncodeUTF8(cRet))
    
return(.T.) 


static Function GetCtt()
    
    Local jUo
    Local cQuery  := ""
    Local cAliasQry := GetNextAlias()
    Local aRet := {}
   
    cQuery := " SELECT CTT_CUSTO, CTT_DESC01, CTT_BLOQ "
    cQuery += " FROM  "+RetSqlName("CTT")+" as CTT "
    cQuery += " WHERE CTT.D_E_L_E_T_ <> '*' "
    cQuery += " AND CTT_BLOQ <> '1' "
    
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry)

    While (cAliasQry)->(!Eof())
        jUo:= JsonObject():New()
        jUo['Codigo'] := AllTrim((cAliasQry)->CTT_CUSTO)
        jUo['Descricao'] := AllTrim((cAliasQry)->CTT_DESC01)
      
        AADD(aRet,jUo)
        (cAliasQry)->(dbSkip())
        FreeObj(jUo)
    EndDo
    (cAliasQry)->(dbCloseArea())

Return (aRet)


//Script teste da funcao 
USER FUNCTION TSTWSOU()
    Local cDados:= '{"usuario":"000000"}'
    Local cCodEmp       := "01MG001"
    Local cCodFil       := "01MG" 
    WFPrepEnv(cCodEmp, cCodFil)
    U_TESTEWSR(cDados)
    RpcClearEnv()
RETURN


