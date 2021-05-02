#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "RESTFUL.CH"


WSRESTFUL WSRCONTRAT DESCRIPTION "WS Rest para integracao com SIGACNT"

    WSMETHOD GET DESCRIPTION "Metodo GET para listagem de contratos "  WSSYNTAX "/WSRCONTRAT/"
 
END WSRESTFUL 

WSMETHOD GET WSSERVICE WSRCONTRAT
 //User Function TSTCNT()
   
    Local cRet  := '{"mensagem":" "}'
    Local lRet  := .T.
    Local cBody := ""
    Local jReq    := JSonObject():New()
    
    Local cFil := "01MG0014"
    Local cDataIni := DtoS(Date() - 180)

    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    jReq:FromJson(cBody)

    //Valida se as tags chave/valor existes no jSon da request.
    If jReq['Filial'] == Nil 
        cRet := '{"mensagem":"Chave Filial não informada, pode ser colocado conteudo em branco"}'
        lRet := .F.
     ElseIf jReq['DataIni'] == Nil
        cRet := '{"mensagem":"Chave DataIni não informada pode ser colocado conteudo em branco"}'
        lRet := .F.
    EndIf

    If lRet == .F.
        ::SetStatus(400)
        ::SetResponse(EncodeUTF8(cRet))
    EndIf

    If !Empty(AllTrim(jReq['Filial']))
        cFil := AllTrim(jReq['Filial'])
    EndIf

    If !Empty(AllTrim(jReq['DataIni']))
        If len(AllTrim(jReq['DataIni'])) == 10
            cDataIni := AllTrim(jReq['DataIni'])
            cDataIni := Right(cDataIni,4)+SubStr(cDataIni,4,2)+Left(cDataIni,2)
        EndIf
    EndIf

    If lRet == .T.
        cRet := StartJob("U_JobLista",getenvserver(),.T.,cFil, cDataIni)
        conout(cRet)
        ::SetResponse( EncodeUTF8(cRet))
    EndIf

return(.T.)

user function JobLista(cFil, cDataIni)
    Local jRes  := JSonObject():New()
    Local jCnt
    Local cRet
    Local cQuery := " "
    Local cAliasQry := GetNextAlias()
    Local aRet := {}
    Local lMudaFil := .F.

    lMudaFil := RpcSetEnv( "01","01MG0001", , , "GCT") // FIEMG
   
    cQuery := " SELECT CN9.CN9_FILIAL,CN9.CN9_NUMERO,CN9.CN9_DTINIC, CN9.CN9_DTFIM, CN9.CN9_SITUAC, CN9_XUNGES, CN9_XNPDCR,
    cQuery += " CNC_CLIENT,  CNC_LOJACL, CNA.CNA_NUMERO AS PLANILHA, CNA.CNA_VLTOT, CNA.CNA_SALDO,  "
    cQuery += " CNB.CNB_ITEM, CNB.CNB_PRODUT, CNB.CNB_DESCRI, CNB.CNB_VLUNIT "
    cQuery += " FROM  "+RetSqlName("CN9")+" AS CN9 "
    cQuery += " INNER JOIN "+RetSqlName("CNC")+" AS CNC ON CN9.CN9_FILIAL = CNC.CNC_FILIAL AND  CN9.CN9_NUMERO = CNC.CNC_NUMERO AND CNC.D_E_L_E_T_ <> '*' "
    cQuery += " INNER JOIN "+RetSqlName("CNA")+" AS CNA ON CN9.CN9_FILIAL = CNA.CNA_FILIAL AND  CN9.CN9_NUMERO = CNA.CNA_CONTRA "
    cQuery += " AND CNC.CNC_CLIENT = CNA.CNA_CLIENT AND CNC.CNC_LOJACL = CNA.CNA_LOJACL AND CNA.D_E_L_E_T_ <> '*' "
    cQuery += " INNER JOIN "+RetSqlName("CNB")+" AS CNB ON CN9.CN9_FILIAL = CNB.CNB_FILIAL AND  CN9.CN9_NUMERO = CNB.CNB_CONTRA AND CNB.D_E_L_E_T_ <> '*' "
    cQuery += " WHERE CN9.D_E_L_E_T_ <> '*' "
    cQuery += " AND CN9_ESPCTR = '2' " // <- Apenas Contratos de Venda
    cQuery += " AND CN9.CN9_SITUAC = '05' " // <- Apenas Contratos Aprovados Vigentes
    cQuery += " AND CNA.CNA_SALDO >'0' "
    cQuery += " AND CN9_DTFIM >= '"+DtoS(DATE())+"' "
    cQuery += " AND CN9_DTINIC >= '"+cDataIni+"'  AND CN9_FILIAL = '"+cFil+"' "
    

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry)

    While (cAliasQry)->(!Eof())

        jCnt := JsonObject():New()

        cNome := AllTrim(POSICIONE("SA1",1,xFilial("SA1")+(cAliasQry)->CNC_CLIENT+(cAliasQry)->CNC_LOJACL, "A1_NOME"))
         //Informacoes do cabecaho contrato 
        jCnt['Filial']      := AllTrim((cAliasQry)->CN9_FILIAL)
        jCnt['contrato']    := AllTrim((cAliasQry)->CN9_NUMERO)
        jCnt['DtInicio']    := SToD((cAliasQry)->CN9_DTINIC)
        jCnt['DtFim']       := SToD((cAliasQry)->CN9_DTFIM)
        jCnt['Situacao']    := AllTrim((cAliasQry)->CN9_SITUAC)
        jCnt['CodCliente']  := AllTrim((cAliasQry)->CNC_CLIENT)
        jCnt['NomeCliente'] := cNome
        jCnt['LojaCliente'] := AllTrim((cAliasQry)->CNC_LOJACL)
        jCnt['UndGestora']  := AllTrim((cAliasQry)->CN9_XUNGES)
        jCnt['PedCRM']      := AllTrim((cAliasQry)->CN9_XNPDCR)
         //informacoes planilha financeira
        jCnt['Planilha']    := AllTrim((cAliasQry)->PLANILHA)
        jCnt['QtdContrato'] := (cAliasQry)->CNA_VLTOT
        jCnt['QtdSaldo']    := (cAliasQry)->CNA_SALDO
         //informacoes produto item da planilha
        jCnt['Item']        := AllTrim((cAliasQry)->CNB_ITEM)
        jCnt['CodProduto']  := AllTrim((cAliasQry)->CNB_PRODUT)
        jCnt['DescProduto'] := AllTrim((cAliasQry)->CNB_DESCRI)
        jCnt['VldUnitario'] := (cAliasQry)->CNB_VLUNIT
        
        AADD(aRet,jCnt)
        (cAliasQry)->(dbSkip())
        FreeObj(jCnt)
    EndDo

    (cAliasQry)->(dbCloseArea())

    jRes['Response'] := aRet
    cRet := jRes:ToJson()

    If lMudaFil
        RpcClearEnv()
    EndIf

Return (cRet)


