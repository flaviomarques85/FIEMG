#Include "TOTVS.CH"
#Include "RESTFUL.CH"
  
WSRESTFUL WSRPEDIDO DESCRIPTION "Rest de inclusao pedido de venda no sistema"

    WSMETHOD POST DESCRIPTION "Metodo POST para inclui pedido de venda"  WSSYNTAX "/WSRPEDIDO/"
 
END WSRESTFUL 

WSMETHOD POST WSSERVICE WSRPEDIDO
//USER Function WSRPED(cDados)
    Local cBody   //:= cDados
    Local jReq    := JSonObject():New()
    Local jRes    := JSonObject():New()

    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.
    Private lAutoErrNoFile := .F.

    ::SetContentType("application/json")  
    cBody  := ::GetContent()
    
    jReq:FromJson(cBody)

    lRet := putPedido(jReq)   

    If lRet
        ::SetResponse('{"message":"OK - Pedido incluso com sucesso "}') 
     Else
        ::SetStatus(400)
        ::SetResponse( EncodeUTF8( '{"message":"Erro na inclus�o do pedido "}' ) )
    EndIf
RETURN(.T.) 

static Function putPedido(jReq)
    Local aLnItens:= {}
    Local aHeader := {} // INFORMA��ES DO CABE�ALHO
    Local aLine   := {} // INFORMA��ES DA LINHA
    Local aItems  := {} // CONJUNTO DE LINHAS
    Local cCodClie:= getCodCli(jReq['cgc'])
    Local nX := 0
    Local cFilial := jReq['filial']

    IF cCodClie $ 'CNPJ'
        Return {.F.,cCodClie}
    EndIf
    
    //AADD(aHeader, {"C5_FILIAL",cFilial,Nil})
    AAdd(aHeader, {"C5_TIPO", "N", NIL})
    AAdd(aHeader, {"C5_CLIENTE", cCodClie, NIL})
    //AAdd(aHeader, {"C5_LOJACLI", jReq['lojaCli'], NIL})
    //AAdd(aHeader, {"C5_LOJAENT", jReq['lojaEnt'], NIL})
    AAdd(aHeader, {"C5_CONDPAG", jReq['condPag'], NIL})
    AAdd(aHeader, {"C5_NATUREZA", jReq['natureza'], NIL})
    AAdd(aHeader, {"C5_TPFRETE", "S", NIL})
    AAdd(aHeader, {"C5_MDCONTR", jReq['contrato'], NIL})
    AAdd(aHeader, {"C5_MDNUMED", jReq['medicao'], NIL})
    If jReq['mensagem'] <> NIL
        AAdd(aHeader, {"C5_XMENNFS", UPPER( removeChar( jReq['mensagem'] ) ), NIL})  ////Habilitar em Producao
    EndIf
    /*If jReq['mensagem'] <> NIL
        AAdd(aHeader, {"C5_MENNOTA", UPPER( removeChar( jReq['mensagem'] ) ), NIL})  //Desabilitar em Producao
    EndIf*/
    AADD(aHeader, {"C5_XUSER",jReq['usuario']})

    aLnItens := jReq['itens']

    For nX := 1 To Len(aLnItens)
        //AADD(aline, {"C6_FILIAL", cFilial, Nil})
        AAdd(aLine, {"C6_PRODUTO",aLnItens[nX]['codProduto'], NIL})
        AAdd(aLine, {"C6_QTDVEN", aLnItens[nX]['quantidade'], NIL})
        AAdd(aLine, {"C6_PRUNIT", aLnItens[nX]['precoUnit'], NIL})
        AAdd(aLine, {"C6_PRCVEN", aLnItens[nX]['precoUnit'], NIL})
        AAdd(aLine, {"C6_VALOR",  aLnItens[nX]['ValorTotal'], NIL})
        AAdd(aLine, {"C6_TES",    aLnItens[nX]['tes'], NIL})
        AAdd(aLine, {"C6_QTDLIB", 0, NIL})
        AAdd(aLine, {"C6_OPER",   aLnItens[nX]['tipoOp'], NIL})
        AAdd(aLine, {"C6_XCC",    aLnItens[nX]['uo'], NIL})
        AAdd(aLine, {"C6_XITEMC", aLnItens[nX]['cr'], NIL})
        AAdd(aLine, {"C6_XCLVL",  aLnItens[nX]['clvl'], NIL})   

        AAdd(aItems, aLine)
        aLine := {}
    Next nX  
    MsExecAuto({|x, y, z| MATA410(x, y, z)}, aHeader, aItems, 3)

    // VALIDA��O DE ERRO
    If (lMsErroAuto)
        MostraErro("/system/")//Remover pois so funciona com tela smartclient
        lRet := .F.
        ConOut(Repl("-", 80))
        ConOut(PadC("Nao foi possivel gravar o pedido, mais informa��es no log /system/", 80))
        ConOut(PadC("Ended at: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        lRet := .T.
        ConOut(Repl("-", 80))
        ConOut(PadC("Gravacao de pedido realizada com sucesso!", 80))
        ConOut(PadC("Ended at: " + Time(), 80))
        ConOut(Repl("-", 80))
    EndIf


return lRet

static function getCodCli(cCGC)

    Local cRet := ""
    dbselectArea("SA1")
	dbGoTop()
    dbSetOrder(3)
    If( SA1->(dbSeek(xFilial("SA1")+cCGC)) )
        cRet := SA1->A1_COD
     Else
        cRet := "CNPJ / CPF Invalido ou inexistente"
    EndIf
    dbCloseArea()
return cRet

static function removeChar(cTexto)
    Local cStringOk := cTexto
    Local nX
    Local nAux

    cStringOk = STRTRAN(cStringOk, "�", "a")
    cStringOk = STRTRAN(cStringOk, "�", "e")
    cStringOk = STRTRAN(cStringOk, "�", "i")
    cStringOk = STRTRAN(cStringOk, "�", "o")
    cStringOk = STRTRAN(cStringOk, "�", "u")
    cStringOk = STRTRAN(cStringOk, "�", "A")
    cStringOk = STRTRAN(cStringOk, "�", "E")
    cStringOk = STRTRAN(cStringOk, "�", "I")
    cStringOk = STRTRAN(cStringOk, "�", "O")
    cStringOk = STRTRAN(cStringOk, "�", "U")
    cStringOk = STRTRAN(cStringOk, "�", "a")
    cStringOk = STRTRAN(cStringOk, "�", "o")
    cStringOk = STRTRAN(cStringOk, "�", "A")
    cStringOk = STRTRAN(cStringOk, "�", "O")
    cStringOk = STRTRAN(cStringOk, "�", "a")
    cStringOk = STRTRAN(cStringOk, "�", "e")
    cStringOk = STRTRAN(cStringOk, "�", "i")
    cStringOk = STRTRAN(cStringOk, "�", "o")
    cStringOk = STRTRAN(cStringOk, "�", "u")
    cStringOk = STRTRAN(cStringOk, "�", "A")
    cStringOk = STRTRAN(cStringOk, "�", "E")
    cStringOk = STRTRAN(cStringOk, "�", "I")
    cStringOk = STRTRAN(cStringOk, "�", "O")
    cStringOk = STRTRAN(cStringOk, "�", "U")
    cStringOk = STRTRAN(cStringOk, "�", "c")
    cStringOk = STRTRAN(cStringOk, "�", "C")
    cStringOk = STRTRAN(cStringOk, "�", "a")
    cStringOk = STRTRAN(cStringOk, "�", "A")
    cStringOk = STRTRAN(cStringOk, "�", "a")
    cStringOk = STRTRAN(cStringOk, "�", "e")
    cStringOk = STRTRAN(cStringOk, "�", "i")
    cStringOk = STRTRAN(cStringOk, "�", "o")
    cStringOk = STRTRAN(cStringOk, "�", "u")
    cStringOk = STRTRAN(cStringOk, "�", "A")
    cStringOk = STRTRAN(cStringOk, "�", "E")
    cStringOk = STRTRAN(cStringOk, "�", "I")
    cStringOk = STRTRAN(cStringOk, "�", "O")
    cStringOk = STRTRAN(cStringOk, "�", "U")
    cStringOk = STRTRAN(cStringOk, "�", ".")
    cStringOk = STRTRAN(cStringOk, "�", ".")
    cStringOk = STRTRAN(cStringOk, "�", ".")
    cStringOk = STRTRAN(cStringOk, "&", " ")
    cStringOk = STRTRAN(cStringOk, chr(9), " ")   
    cStringOk := FwCutOff(cStringOk,.T.)
    
   For nX := 1 To Len(cStringOk)
   		nAux := Asc(Substr(cStringOk,nX,1))
   		If nAux <> 32 .And. !(nAux >= 48 .And. nAux <= 57) .And. !(nAux >= 65 .And. nAux <= 122)   		
   			cStringOk := strtran(cStringOk, chr(nAux), Space(1))
   		Endif	
   Next nX
return cStringOk


static Function testaPv()
Local cDados := ""

cDados += '{ '
cDados += '"CGC":"18516305000120", '
cDados += '"tipo":"N", '
cDados += '"cliente":"002040", '
cDados += '"lojaCli":"01", '
cDados += '"lojaEnt":"01", '
cDados += '"natureza":"ISS", '
cDados += '"condPag":"001", '
cDados += '"contrato":"0000179855", '
cDados += '"medicao":"11229", '
cDados += '"mensagem":"Uma MSG p�ra n�t�, pode ser informacao d� transporte por�m sem acent� ou cara�ter esp�ci�l", '
cDados += '"itens": [ '
cDados += '           { '
cDados += '             "codProduto":"00879956", '
cDados += '             "quantidade": 5, '
cDados += '             "precoUnit":5.99, '
cDados += '             "precoVenda":5.99, '
cDados += '             "ValorTotal":29.95, '
cDados += '             "TES" : "555", '
cDados += '             "UO" : "MG110", '
cDados += '             "CR" : "115" '
cDados += '           }, '
cDados += '           { '
cDados += '             "codProduto":"03130094", '
cDados += '             "quantidade": 1, '
cDados += '             "precoUnit":10.78, '
cDados += '             "precoVenda":10.78, '
cDados += '             "ValorTotal":10.78, '
cDados += '             "tes" : "555", '
cDados += '             "uo" : "MG110", '
cDados += '             "cr" : "115" '
cDados += '             } '
cDados += '         ] '
cDados += '  }'

Return cDados

/*{
   "filial":"01MG0049",
   "cgc":"05873241000169",
   "tipo":"N",
   "natureza":"100010",
   "condPag":"001",
   "contrato":"",
   "medicao":"",
   "mensagem":"Uma MSG p�ra n�t�, pode ser informacao d� transporte por�m sem acent� ou cara�ter esp�ci�l",
   "usuario":"apiS+",
   "itens":[
      {
         "codProduto":"000000000098161",
         "quantidade":5,
         "precoUnit":5.99,
         "valorTotal":29.95,
         "qtdLiberada":0,
         "tipoOp":"01",
         "tes":"636",
         "uo":"10810",
         "cr":"3332",
         "clvl":"000400001"
      }
   ]
}
*/
