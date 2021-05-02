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
    Local cRet  := ""
    Local cBody := ""//'{"Filial":"02", "Contrato":"000000000000002", "Quantidade":1,"PedCRM":"000001367"}'
    Local aParm := {} 
    ::SetContentType("application/json")  
    cBody  := ::GetContent() 
    jReq:FromJson(cBody)

     If jReq['Filial'] == Nil 
        cRet := '{"mensagem":"faltou informar filial"}'
     ElseIf !SM0->(DbSeek("01"+AllTrim(jReq['Filial'])))
        cRet := '{"mensagem":"Filial informada não pertence ao grupo de Empresas"}'
     ElseIf jReq['Contrato'] == Nil 
        cRet := '{"mensagem":"faltou numero do contrato"}' 
     ElseIf jReq['Quantidade'] == Nil 
        cRet := '{"mensagem":"faltou quantidade ou valor de itens"}'
     ElseIf jReq['Valor'] == Nil
        cRet := '{"mensagem":"faltou  valor de itens, pode ser Zerado caso nao tenha"}'
    EndIf

    If !Empty(cRet)
        ::SetStatus(400)
        ::SetResponse(cRet)
        lRet := .F.
    EndIf
    
    If lRet
        AADD(aParm,jReq['Filial'])
        AADD(aParm,jReq['Contrato'])
        AADD(aParm,jReq['Quantidade'])
        AADD(aParm,jReq['Valor'])
         
        aRet := StartJob("U_WSRJOB",getenvserver(),.T.,aParm)

        ::SetStatus(aRet[3])
        ::SetResponse(aRet[2])
    EndIf
Return(.T.) 


User Function WSRJOB(aParm)
    Local cMsg := ""
    Local nStatus := 400
    Local oModel    := Nil
    local cFilCTR   := ""
    Local cCodCTR   := "000000000000006"
    Local cNumMed   := ""
    Local aMsgDeErro:= {}
    Local lRet      := .T. 
    Local lMudaFil  := .F.
    Local cMsgErro      := ""
    Local nX        := 0
    Local nVlrTotal := 0
    Local nVlrMedic := 0
    /*
        aParm[1] - Filial
        aParm[2] - Contrato
        aParm[3] - Quantidade
        aPArm[4] - Valor
    */
            
    lMudaFil := RpcSetEnv( "01",aParm[1], , , "GCT")
     
    cFilCTR  := AllTrim(aParm[1])
    cCodCTR  := aParm[2]
    nQtd     := aParm[3]
    nVlrMedic:= aParm[4]
   

    //Valida tipo de dado vindo da request
    If !ValType(nQtd) == 'N' .AND. ValType(nQtd) == 'C'
        nQtd := val(nQtd)
    EndIf

    If !ValType(nVlrMedic) == 'N' .AND. ValType(nVlrMedic) == 'C'
        nVlrMedic := val(nVlrMedic)
    EndIf

    dbSelectArea("CN9") 
    CN9->(DbSetOrder(1))
        
    If CN9->(DbSeek(cFilCTR + cCodCTR))//Posicionar na CN9 para realizar a inclusão
        If nQtd > CN9->CN9_SALDO
            nStatus := 400
            cMsg := '{"mensagem":"Quantidade enviada maior que saldo do contrato, verifique!"}'
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

                nVlrTotal := oModel:GetValue('CNEDETAIL' , 'CNE_VLUNIT' ) //Round(M->CNE_VLTOT/M->CNE_VLUNIT,TamSX3("CNE_QUANT")[2])              
                If nVlrMedic > 0
                    oModel:SetValue( 'CNEDETAIL' , 'CNE_VLTOT'  , nVlrMedic) //Caso seja informado valor total  
                 Else                           
                    oModel:SetValue( 'CNEDETAIL' , 'CNE_QUANT'  , nQtd)  
                EndIf        
                
                If (oModel:VldData()) /*Valida o modelo como um todo*/
                    oModel:CommitData()
                EndIf
            EndIf
            
            If(oModel:HasErrorMessage())
                aMsgDeErro := oModel:GetErrorMessage()
                For nX := 1 to len(aMsgDeErro)
                    If ValType(aMsgDeErro[nX]) == 'C'
                        cMsgErro += aMsgDeErro[nX] + ", "
                    EndIf
                next
                nStatus := 400
                cMsg := '{"mensagem":"'+cMsgErro+'"}'
                lRet := .F.
            Else
                cNumMed := CND->CND_NUMMED         
                oModel:DeActivate()        
                lRet := CN121Encerr(.T.) //Realiza o encerramento da medição        
                If lRet
                    nStatus := 200
                    cMsg := '{"Status":"Sucesso","mensagem":"Pedido foi incluido e a medicao '+cNumMed+' encerrada."}'
                Else
                    nStatus := 201
                    cMsg := '{"mensagem":"A medicao '+cNumMed+' foi enviada ao ERP porem nao encerrada, verifique a medicao no ERP."}'
                EndIf            
            EndIf
        EndIf
        Else // Se nao achou o contrato 
        nStatus := 400
        cMsg := '{"mensagem":"Contrato nao localizado!"}'
    EndIf  
        
    IF (lMudaFil) 
        //RESET ENVIRONMENT 
        RpcClearEnv()
    EndIf
  
Return {lRet,cMsg,nStatus}

//Troca Empresa
User Function ChangeEmp(cEmp, cFil)

	dbcloseall()
	Opensm0(cEmp+cFil)
 	Openfile(cEmp+cFil)
	       
Return
