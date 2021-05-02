#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "RESTFUL.CH"
#include "TBICONN.CH"

WSRESTFUL WSRMEDICAO DESCRIPTION "WS Rest para integracao com SIGACNT"

    WSMETHOD POST DESCRIPTION "Metodo POST para incluir uma medicao e encerrar-la "  WSSYNTAX "/WSRMEDICAO/"
 
END WSRESTFUL 

WSMETHOD POST WSSERVICE WSRMEDICAO 
//User Function TSTMEDIC() 
    Local oModel    := Nil
    local cFilCTR   := ""
    Local cCodCTR   := "000000000000006"
    Local cNumMed   := ""
    Local aMsgDeErro:= {}
    Local lRet      := .T. 
    Local lMudaFil  := .F.
    Local cMsgErro      := ""
    Local nX        := 0
    Local jReq    := JSonObject():New()
    //Local jRes    := JSonObject():New()
    Local cRet  := ""
    Local cBody := ""//'{"Filial":"02", "Contrato":"000000000000002", "Quantidade":1,"PedCRM":"000001367"}'
     
    ::SetContentType("application/json")  
    cBody  := ::GetContent() 
    jReq:FromJson(cBody)

     If jReq['Filial'] == Nil 
        cRet := '{"mensagem":"faltou informar filial"}'
     ElseIf jReq['PedCRM'] == Nil
        cRet := '{"mensagem":"faltou numero do Pedido CRM"}'
     ElseIf jReq['Contrato'] == Nil 
        cRet := '{"mensagem":"faltou numero do contrato"}' 
     ElseIf jReq['Quantidade'] == Nil
        cRet := '{"mensagem":"faltou quantidade de itens"}'
    EndIf

    If !Empty(cRet)
        ::SetStatus(400)
        ::SetResponse(cRet)
        lRet := .F.
    EndIf
    
    if AllTrim(jReq['Filial']) != cFilAnt .AND. lRet == .T.
         
        lMudaFil := RpcSetEnv( "99","02", , , "GCT")
        U_ChangeEmp("99",AllTrim(jReq['Filial']))
        
    EndIf

    If lRet == .T.
        cFilCTR := AllTrim(jReq['Filial'])
        cCodCTR := jReq['Contrato']
        nQtd    := jReq['Quantidade']

        If !ValType(nQtd) == 'N' .AND. ValType(nQtd) == 'C'
            nQtd := val(nQtd)
        EndIf

        dbSelectArea("CN9") 
        CN9->(DbSetOrder(1))
            
        If CN9->(DbSeek(cFilCTR + cCodCTR))//Posicionar na CN9 para realizar a inclusão
            If nQtd > CN9->CN9_SALDO
                ::SetStatus(400)
                cRet := '{"mensagem":"Quantidade enviada maior que saldo do contrato, verifique!"}'
                ::SetResponse(EncodeUTF8(cRet))
                lRet := .F.
             Else
                oModel := FWLoadModel("CNTA121")
                
                oModel:SetOperation(MODEL_OPERATION_INSERT)
                If(oModel:CanActivate())           
                    oModel:Activate()
                    oModel:SetValue("CNDMASTER","CND_CONTRA"    ,CN9->CN9_NUMERO)
                    oModel:SetValue("CNDMASTER","CND_RCCOMP"    ,"1")//Selecionar competência
                    
                    oModel:SetValue("CXNDETAIL","CXN_CHECK" , .T.)//Marcar a planilha(nesse caso apenas uma)           
                    oModel:GetModel('CNEDETAIL'):GoLine(1)
                    oModel:SetValue( 'CNEDETAIL' , 'CNE_QUANT'  , nQtd)           
                    
                    If (oModel:VldData()) /*Valida o modelo como um todo*/
                        oModel:CommitData()
                    EndIf
                EndIf
                
                If(oModel:HasErrorMessage())
                    aMsgDeErro := oModel:GetErrorMessage()
                    For nX := 1 to len(aMsgDeErro)
                        cMsgErro += aMsgDeErro[nX]
                    next
                    ::SetStatus(400)
                    cRet := '{"mensagem":"'+cMsgErro+'"}'
                    lRet := .F.
                 Else
                    cNumMed := CND->CND_NUMMED         
                    oModel:DeActivate()        
                    lRet := CN121Encerr(.T.) //Realiza o encerramento da medição        
                    If lRet
                        ::SetStatus(200)
                        cRet := '{"Status":"Sucesso","mensagem":"Pedido foi incluido e a medicao '+cNumMed+' encerrada."}'
                        ::SetResponse(EncodeUTF8(cRet))
                    Else
                        ::SetStatus(201)
                        cRet := '{"mensagem":"A medicao '+cNumMed+' foi enviada ao ERP porem nao encerrada, verifique a medicao no ERP."}'
                        ::SetResponse(EncodeUTF8(cRet))
                    EndIf            
                EndIf
            EndIf
         Else // Se nao achou o contrato 
            ::SetStatus(400)
            cRet := '{"mensagem":"Contrato nao localizado!"}'
            ::SetResponse(EncodeUTF8(cRet))
        EndIf  
    EndIf
    IF (lMudaFil) 
        //RESET ENVIRONMENT 
        RpcClearEnv()
    EndIf
Return(.T.) 

//Script teste da funcao 
USER FUNCTION TSTWSN()
    Local cDados:= '{"Filial":"02", "Contrato":"000000000000002", "Quantidade":1,"PedCRM":"000001367"}'
    Local cCodEmp       := "99"
    Local cCodFil       := "01" 
    WFPrepEnv(cCodEmp, cCodFil)
    U_TSTMEDIC()
    RpcClearEnv()
RETURN
/*
User Function ALTEMP(cEmp, cFil)

Local cemp:=cEmp
Local cfil:=cFil
	
	dbcloseall()
	cempant :=cemp
	cfilant :=cfil 
	cNumEmp :=cemp+cfil
	Opensm0(cempant+cfil)
 	Openfile(cempant+cfil)
	lrefresh :=.T.
	       
Return
*/
User Function ChangeEmp(cEmp, cFil)

	dbcloseall()
	Opensm0(cEmp+cFil)
 	Openfile(cEmp+cFil)
	       
Return
