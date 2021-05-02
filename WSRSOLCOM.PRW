#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "RESTFUL.CH"
#include "TBICONN.CH"

WSRESTFUL WSRSOLCOM DESCRIPTION "WS Rest para integracao com SIGACOM - SC"

    WSMETHOD POST DESCRIPTION "Metodo POST para incluir uma SC no sistema com informaçõe do S+ "  WSSYNTAX "/WSRSOLCOM/"
 
END WSRESTFUL 

WSMETHOD POST WSSERVICE WSRSOLCOM 

    Local cFil:= ""
    Local cUO := ""
    Local cCR := ""
    Local cTipoDOC := ""
    Local cUnidReq := ""
    Local dDatabase := Date()

    Local cProduto := ""
    Local nQtd := 0
    Local nValor:= 0
    Local cFinalCom := "084"
    Local cCLVL := ""

    Local lRet  := .F.
    Local cBody //:= '{"Filial":"01","Uo":"10310","Cr":"3353","TipoDoc":"003","UnidadeRequis":"12215","Produto":"03130094","Quantidade":2.0, "Valor":1.0, "FinalidadeCompra":"084", "ClasseValor":"000400001"}'
    Local jReq  := JsonObject():New()
    
    Local aHeader := {}
    Local aItens  := {}
    Local nX      := 0

    ::SetContentType("application/json")  
    cBody  := ::GetContent() 

    jReq:FromJson(cBody)

    cFil        := jReq['Filial']
    cUO         := jReq['Uo']
    cCR         := jReq['Cr']
    cTipoDOC    := jReq['TipoDoc']
    cUnidReq    := jReq['UnidadeRequis']
    cSolicit    := jReq['Solicitante']

    cProduto    := jReq['Produto']
    nQtd        := jReq['Quantidade']
    nValor      := jReq['Valor']
    cFinalCom   := jReq['FinalidadeCompra']
    cCLVL       := jReq['ClasseValor']

    
    aHeader	:={	    { "C1_FILIAL"	, cFil      , NIL},;
                    { "C1_SOLICIT"	, cSolicit  , NIL},;
                    { "C1_ITEMCTA"	, cCR       , NIL},; // CR - FIEMG
                    { "C1_CC"	    , cUO       , NIL},; // Unidade Organizacional - FIEMG
                    { "C1_XTIPOSC"	, cTipoDOC  , NIL},; // Tipo Documento - FIEMG
                    { "C1_USER"     ,'001758'   , NIL},; //  Requisitante SC - FIEMG
                    { "C1_EMISSAO"	, dDatabase , NIL},;
                    { "C1_UNIDREQ"	, cUnidReq  , NIL} ;
                }
    for nX := 1 to len(aHeader[1])
        if Empty(aHeader[1][nX])
            lRet := .F.
        endif
    next
    
    
    			
    aAdd(aItens,	{	{"C1_ITEM"		, "0001"    , NIL},;	//	Item da SC
                        {"C1_PRODUTO"	, cProduto  , NIL},;	//	Produto
                        {"C1_QUANT"		, nQtd      , NIL},;	//	Quantidade
                        {"C1_VUNIT"		, nValor    , NIL},;    //  Valor unitario - FIEMG 
                        {"C1_CC"		, cUO       , NIL},;	//	Centro de Custo
                        {"C1_FINCOM"    ,cFinalCom  , NIL},;    //  Finalidade Compras - FIEMG
                        {"C1_CLVL"		, cCLVL     , NIL}})	//	Classe Valor
                        

    aRet := StartJob("U_ws110job",getenvserver(),.T., aHeader, aItens)

    if valtype(aRet) <> 'A'
        ::SetStatus(400)
        ::SetResponse('{"mensagem":"Problemas no StartJob. Verifique as informacoes passadas, caso estejam certas contate o administrador"}')
     else
        ::SetStatus(aRet[1][2])
        ::SetResponse(aRet[1][3])
    endif

Return(.T.)

User function ws110job(aHeader, aItens)

    Local aRet := {}
    Local lMudaFil
    Local cResp := ""
    Local nStatus := 200

    Local lMsErroAuto	:= .F.
    Local cErro         := ""
    Local nX            := 0
    Local aLogError     := {}

    RpcSetType(3)
    lMudaFil := RpcSetEnv( "01",aHeader[1][2], , , "COM")


    MSExecAuto({|X,Y,Z| Mata110(X,Y,Z)}, aHeader, aItens, 3) //insere a SC no novo numero

    If lMsErroAuto
        lRet	 :=	.F.
        nStatus  := 400
        aLogError:= GetAutoGRLog()

        For nX := 1 To Len(aLogError)
            If !Empty(cErro)
                cErro += CRLF
            EndIf
            cErro += aLogError[nX]
        Next nX
        
        cResp := '{"mensagem":"Problemas na execucao da Rotina Automatica MATA110 [INCLUSAO] "'+cErro+'}'
        
     else
        lret := .T.  
        nStatus := 200
        cResp := '{"mensagem":"sucesso"}'
    EndIf

    AADD(aRet,{lRet,nStatus,cResp})

    if (lMudaFil) 
        //RESET ENVIRONMENT 
        RpcClearEnv()
    endif

return(aRet)

/*//funcao de testes
//{"Filial":"01","Uo":"10310","Cr":"3353","TipoDoc":"003","UnidadeRequis":"12215","Produto":"000000000870610","Quantidade":1.0, "Valor":1.0, "FinalidadeCompra":"084", "ClasseValor":"00400001"}
user function WSTST()
    RpcSetType(3)
    RpcSetEnv("99", "01",,,'COM') 

    U_WSRSOLCOM()

    RpcClearEnv()
Return*/

