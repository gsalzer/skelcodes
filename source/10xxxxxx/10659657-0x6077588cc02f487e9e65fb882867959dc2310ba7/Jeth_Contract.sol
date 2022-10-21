pragma solidity ^0.4.24;
 /**
     ____
     \\  `.
      \\   `.
       \ \   `.
        \\JETH`.
        :. . . . `._______________________.-~|~~-._
        \                                 ---'-----`-._
         /"""""""/             _...---------..         ~-._________
        //     .`_________  .-`           \ .-~           /
       //    .'       ||__.~             .-~_____________/
      //___.`           .~            .-~
                      .~           .-~
                    .~         _.-~
                    `-_____.-~'
 */
contract Jeth_Contract {
    
 address private owner;
 address private Cover=0x76B6A7a62Ed6F791469F14825a8B7d82A67D8Aee;
 // 0xFA107001d47337Dd379423905F66A6c9EA97D092
 address private Jeth_pot=0x9d4eb5bF95AB0195c27C87DB18AB43aedFCB2680;
 address private rein;
 
     struct Pasajero {
        uint id;
        address billetera;
        address[] referidos;
        uint[] pagos;
        address referido_unico;
    }
 mapping (address => Pasajero) pasaje;
 uint[] private pasajeroscont;
 uint ids=1;
 
 address[]private tourist_cabin_1;
 address[]private tourist_cabin_2;
 address[]private tourist_cabin_3;
 address[]private tourist_cabin_4;
 address[]private tourist_cabin_5;
 address[]private tourist_cabin_6;
 
 address[]private executive_cabin_1;
 address[]private executive_cabin_2;
 address[]private executive_cabin_3;
 address[]private executive_cabin_4;
 address[]private executive_cabin_5;
 address[]private executive_cabin_6;
 
 
address[]private first_class_cabin_1;
address[]private first_class_cabin_2; 
address[]private first_class_cabin_3;
address[]private first_class_cabin_4; 
address[]private first_class_cabin_5;
address[]private first_class_cabin_6;

uint t1=4;
uint t2=4;
uint t3=4;
uint t4=4;
uint t5=4;
uint t6=4;

uint e1=4;
uint e2=4;
uint e3=4;
uint e4=4;
uint e5=4;
uint e6=4;

uint f1=4;
uint f2=4;
uint f3=4;
uint f4=4;
uint f5=4;
uint f6=4;

string jpok='';

uint[] private total_cabinas;
     constructor() public{
        owner = msg.sender;
    }
 function enter(address invitador) public payable {
        require(msg.value== 0.30 ether);
        require(pasaje[msg.sender].id==0);
        //Esto para el Cover
        send_pays(100000000000000000,Cover);
        //registra
        add(invitador);
        tourist_cabin_1.push(msg.sender);
        //cabinas
        if(tourist_cabin_1.length>=1){
            Procesor_cabina_turista();
        }
        if(executive_cabin_1.length>=1){
            Procesor_cabina_ejecutiva();
        }
        if(first_class_cabin_1.length>=1){
            Procesor_cabina_primera_clase();
        }
 }
 //// funciones de pasajero 
     function add(address delreferido) private {
        Pasajero storage pasajes=pasaje[msg.sender];
        pasajes.id = ids;
        pasajes.billetera = msg.sender;
        pasajes.referidos;
        asing_ref(delreferido,msg.sender);
        pasajes.referido_unico=delreferido;
        pasajeroscont.push(ids) -1;
        ids=ids+1;
    }
     function seach(address a) view public returns (uint, address, address[],address) {
        return (pasaje[a].id, pasaje[a].billetera, pasaje[a].referidos,pasaje[a].referido_unico);
    }
    function asing_ref(address a,address _ref)private{
        send_pays(30000000000000000,a);
        pasaje[a].referidos.push(_ref);
    }
    
    function asing_ref1(address a)private{
       send_pays(300000000000000000, pasaje[a].referido_unico);
    }
    function asing_ref2(address a)private{
       send_pays(900000000000000000, pasaje[a].referido_unico);
    }
    function asing_pagos(address a,uint pago)private{
        pasaje[a].pagos.push(pago);
    }
    function seach_ref_cantidad(address a) view public returns(uint){
        return pasaje[a].referidos.length;
    }
    function seach_pagos(address a) view public returns(uint b,uint[] ar){
        b= pasaje[a].pagos.length;
        ar= pasaje[a].pagos;
    }
 // funciones cabinas
 function Procesor_cabina_turista() private{
       if(tourist_cabin_1.length==t1){
          reinvestment(tourist_cabin_1,tourist_cabin_2, tourist_cabin_1[0] );
          send_pays(1000000000000000,Cover);
          t1=t1+2;
        }
        if(tourist_cabin_2.length==t2){
           send_pays(100000000000000000,tourist_cabin_2[0]);
           asing_pagos(tourist_cabin_2[0],23);
           reinvestment(tourist_cabin_2,tourist_cabin_3, tourist_cabin_2[0] );
           t2=t2+2;
        }
         if(tourist_cabin_3.length==t3){
           send_pays(100000000000000000,tourist_cabin_3[0]);
           asing_pagos(tourist_cabin_3[0],34);
           reinvestment(tourist_cabin_3,tourist_cabin_4, tourist_cabin_3[0] );
           t3=t3+2;
        }
         if(tourist_cabin_4.length==t4){
           send_pays(200000000000000000,tourist_cabin_4[0]);
           asing_pagos(tourist_cabin_4[0],45);
           reinvestment(tourist_cabin_4,tourist_cabin_5, tourist_cabin_4[0] );
           t4=t4+2;
        }
         if(tourist_cabin_5.length==t5){
           send_pays(600000000000000000,tourist_cabin_5[0]);  
           asing_pagos(tourist_cabin_5[0],56);
           reinvestment(tourist_cabin_5,tourist_cabin_6, tourist_cabin_5[0] );
           t5=t5+2;
        }
         if(tourist_cabin_6.length==t6){
          address proceso=tourist_cabin_6[0];
         
          //pagar a usuario 5 eth
           send_pays(4800000000000000000,proceso);
           //0.2 al JP
           send_pays(200000000000000000,Jeth_pot); 
           append(jpok,"1,");
            //0.2 a CT y 0.1 a Cover
           tourist_cabin_1.push(proceso);
           asing_pagos(tourist_cabin_6[0],61);
           send_pays(100000000000000000,Cover);
           // 2 CE y 0.3 Cover
           asing_ref1(proceso);
           executive_cabin_1.push(proceso);
           asing_pagos(tourist_cabin_6[0],161);
           send_pays(300000000000000000,Cover);
           //reinvercion cabina 6
           exit(tourist_cabin_6);
           tourist_cabin_6.push(proceso);
           t6=t6+2;
        }
  }
  function append(string a, string b) internal pure returns (string) {

    return string(abi.encodePacked(a, b));

}
 function Procesor_cabina_ejecutiva() private{
       if(executive_cabin_1.length==e1){
          reinvestment(executive_cabin_1,executive_cabin_2, executive_cabin_1[0] );
          e1=e1+2;
        }
        if(executive_cabin_2.length==e2){
           send_pays(1000000000000000000,executive_cabin_2[0]);
           asing_pagos(executive_cabin_2[0],123);
           reinvestment(executive_cabin_2,executive_cabin_3, executive_cabin_2[0] );
           e2=e2+2;
        }
         if(executive_cabin_3.length==e3){
           send_pays(1000000000000000000,executive_cabin_3[0]);
           asing_pagos(executive_cabin_3[0],134);
           reinvestment(executive_cabin_3,executive_cabin_4, executive_cabin_3[0] );
           e3=e3+2;
        }
         if(executive_cabin_4.length==e4){
           send_pays(2000000000000000000,executive_cabin_4[0]);   
           asing_pagos(executive_cabin_4[0],145);
           reinvestment(executive_cabin_4,executive_cabin_5, executive_cabin_4[0] );
           e4=e4+2;
        }
         if(executive_cabin_5.length==e5){
           send_pays(4000000000000000000,executive_cabin_5[0]);    
           asing_pagos(executive_cabin_5[0],156);
           reinvestment(executive_cabin_5,executive_cabin_6, executive_cabin_5[0] );
           e5=e5+2;
        }
         if(executive_cabin_6.length==e6){
          address proceso=executive_cabin_6[0];
          //pagarle 
           send_pays(71500000000000000000,proceso);
           //0.9 al JP
           send_pays(7900000000000000000,Jeth_pot); 
           append(jpok,"2,");
            //2 a CE y 0.3 a Cover
           executive_cabin_1.push(proceso);
           send_pays(300000000000000000,Cover);
           asing_pagos(executive_cabin_6[0],161);
           // 6 PC y 0.6 Cover
           asing_ref2(proceso);
           first_class_cabin_1.push(proceso);
           asing_pagos(executive_cabin_6[0],261);
           send_pays(600000000000000000,Cover);
           //reinvercion cabina 6
           exit(executive_cabin_6);
           executive_cabin_6.push(proceso);
           e6=e6+2;
        }
  }
 function Procesor_cabina_primera_clase() private{
       if(first_class_cabin_1.length==f1){
          reinvestment(first_class_cabin_1,first_class_cabin_2, first_class_cabin_1[0] );
           f1=f1+2;
        }
        if(first_class_cabin_2.length==f2){
           send_pays(1000000000000000000,first_class_cabin_2[0]);
           asing_pagos(first_class_cabin_2[0],223);
           reinvestment(first_class_cabin_2,first_class_cabin_3, first_class_cabin_2[0] );
           f2=f2+2;
        }
         if(first_class_cabin_3.length==f3){
           send_pays(2000000000000000000,first_class_cabin_3[0]);
            asing_pagos(first_class_cabin_3[0],234);
           reinvestment(first_class_cabin_3,first_class_cabin_4, first_class_cabin_3[0] );
           f3=f3+2;
        }
         if(first_class_cabin_4.length==f4){
           send_pays(4000000000000000000,first_class_cabin_4[0]);     
           asing_pagos(first_class_cabin_4[0],245);
           reinvestment(first_class_cabin_4,first_class_cabin_5, first_class_cabin_4[0] );
           f4=f4+2;
        }
         if(first_class_cabin_5.length==f5){
           send_pays(9000000000000000000,first_class_cabin_5[0]); 
           asing_pagos(first_class_cabin_5[0],256);
           reinvestment(first_class_cabin_5,first_class_cabin_6, first_class_cabin_5[0] );
           f5=f5+2;
        }
         if(first_class_cabin_6.length==f6){
          address proceso=executive_cabin_6[0];
          //pagarle 
           send_pays(292000000000000000000,proceso);
           //0.9 al JP
           send_pays(46800000000000000000,Jeth_pot); 
           append(jpok,"3,");
           // 6 PC y 0.6 Cover
           first_class_cabin_1.push(proceso);
           asing_pagos(first_class_cabin_6[0],261);
           send_pays(600000000000000000,Cover);
           //reinvercion cabina 6
           exit(first_class_cabin_6);
           f6=f6+2;
        }
  }
 function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
 function exit(address[] storage  cabin) private returns(address[]) {
        uint index=0;
        if (index >= cabin.length) return;
        for (uint i = index; i<cabin.length-1; i++){
            cabin[i] = cabin[i+1];
        }
        cabin.length--;
        return cabin;
  }
 function reinvestment(address[] storage  actual,address[] storage  camino, address valor ) private{
        rein=valor;
        camino.push(rein);
        exit(actual);
        actual.push(rein);
    }
 function contabilidad_clase1() view public returns(uint tn1,uint tn2,uint tn3,uint tn4, uint tn5, uint tn6){
      tn1=tourist_cabin_1.length;
      tn2=tourist_cabin_2.length;
      tn3=tourist_cabin_3.length;
      tn4=tourist_cabin_4.length;
      tn5=tourist_cabin_5.length;
      tn6=tourist_cabin_6.length;
 }
 function contabilidad_clase2() view public returns(uint en1,uint en2,uint en3,uint en4, uint en5, uint en6){
      en1=executive_cabin_1.length;
      en2=executive_cabin_2.length;
      en3=executive_cabin_3.length;
      en4=executive_cabin_4.length;
      en5=executive_cabin_5.length;
      en6=executive_cabin_6.length;
 }
 function contabilidad_clase3() view public returns(uint pn1,uint pn2,uint pn3,uint pn4, uint pn5, uint pn6){
      pn1=first_class_cabin_1.length;
      pn2=first_class_cabin_2.length;
      pn3=first_class_cabin_3.length;
      pn4=first_class_cabin_4.length;
      pn5=first_class_cabin_5.length;
      pn6=first_class_cabin_6.length;
 }
 function contar_cabinas(uint cabina)  view public  returns(address[]){
     if(cabina==1){
            return tourist_cabin_1;
     }
      if(cabina==2){
            return tourist_cabin_2;
     }
      if(cabina==3){
            return tourist_cabin_3;
     }
      if(cabina==4){
            return tourist_cabin_4;
     }
      if(cabina==5){
            return tourist_cabin_5;
     }
      if(cabina==6){
            return tourist_cabin_6;
     }
     if(cabina==7){
            return executive_cabin_1;
     }
      if(cabina==8){
            return executive_cabin_2;
     }
      if(cabina==9){
            return executive_cabin_3;
     }
      if(cabina==10){
            return executive_cabin_4;
     }
      if(cabina==11){
            return executive_cabin_5;
     }
      if(cabina==12){
            return executive_cabin_6;
     }
     if(cabina==13){
            return first_class_cabin_1;
     }
      if(cabina==14){
            return first_class_cabin_2;
     }
      if(cabina==15){
            return first_class_cabin_3;
     }
      if(cabina==16){
            return first_class_cabin_4;
     }
      if(cabina==17){
            return first_class_cabin_5;
     }
      if(cabina==18){
            return first_class_cabin_6;
     }
 }
 function jetspo() public view returns(string){
     return jpok;
 }
  function pago(uint amount,address to)public isowner{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    modifier isowner(){
        require(msg.sender==owner);
        _;
    }

}
