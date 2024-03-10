pragma solidity ^0.5.12;

contract Capsule {
    struct Prediction {
        string cid;
        string name;
    }

    Prediction[] public predictions;

    constructor() public {
        predictions.push(Prediction('QmfYfkqemPPuUsfXZhSNEL9449H1fRHVMf9zTU8myCKfkJ', 'Азат Гафаров'));
        predictions.push(Prediction('QmavxbA6E7ptj6A41BxrCTE7WPDEmWquZCZJyKocniAVw9', 'Юрий Бондарь'));
        predictions.push(Prediction('QmXmtQeHJZDT5iNBJ82QnaJNUTo2Aw8bQX9juQwziymqAP', 'Наталья Галян'));
        predictions.push(Prediction('QmXvM7d4zz8WxUJiC1ZVzc6BkH6ZLfDtCsEiDkua7PpiHG', 'Светлана Бова'));
        predictions.push(Prediction('QmQ8UBqhGxTh8thVVxFrvhMSrRbuepP3i9XJt5jsbaowf4', 'Давид Ян'));
    }
}
