// This file handles all communication with the smart contract on Sepolia.
// Transactions are signed by MetaMask via WalletConnect — no private keys ever touched.

import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:frontend/services/wallet_service.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  // Sepolia testnet RPC URL — for reading data only.
  static const String _rpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com';

  // Your deployed contract address on Sepolia.
  static const String _contractAddress = '0xa580076121b3ef551FDEB2C430a9Dbb2785487Ac';

  // Sepolia chain ID.
  static const int _chainId = 11155111;

  // 0.01 ETH in Wei as hex — this is the appointment price.
  static const String _appointmentPriceHex = '0x2386F26FC10000';

  // Contract ABI.
  static const String _abiJson = '''
  [
    {
      "inputs": [{"internalType": "address", "name": "_doctor", "type": "address"}],
      "name": "bookAppointment",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256", "name": "_appointmentId", "type": "uint256"}],
      "name": "cancelByDoctor",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256", "name": "_appointmentId", "type": "uint256"}],
      "name": "cancelByPatient",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256", "name": "_appointmentId", "type": "uint256"}],
      "name": "startMeeting",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "appointmentCounter",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  // Web3 client — used only for READING data from blockchain.
  late final Web3Client _client;
  late final DeployedContract _contract;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    _client = Web3Client(_rpcUrl, http.Client());
    _contract = DeployedContract(
      ContractAbi.fromJson(_abiJson, 'AnonymousDoctor'),
      EthereumAddress.fromHex(_contractAddress),
    );
    _initialized = true;
  }

  // ─────────────────────────────────────────
  // READ — no MetaMask needed, no gas needed.
  // ─────────────────────────────────────────

  // Get current appointment counter — tells us what ID the next appointment gets.
  Future<int> getAppointmentCounter() async {
    await _initialize();
    final function = _contract.function('appointmentCounter');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [],
    );
    return (result.first as BigInt).toInt();
  }

  // Wait for a transaction to be confirmed on the blockchain.
  // Keeps checking every 3 seconds until the receipt comes back.
  Future<void> waitForTransaction(String txHash) async {
    await _initialize();

    // Keep checking until we get a receipt.
    while (true) {
      try {
        final receipt = await _client.getTransactionReceipt(txHash);

        // Receipt exists means transaction is confirmed.
        if (receipt != null) {
          return;
        }
      } catch (e) {
        // Receipt not ready yet — keep waiting.
      }

      // Wait 3 seconds before checking again.
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  // ─────────────────────────────────────────
  // WRITE — all signed by MetaMask via WalletConnect.
  // ─────────────────────────────────────────

  // Encodes a function call into hex data for MetaMask to sign.
  Future<String> _encodeFunctionCall(String functionName, List<dynamic> params) async {
    await _initialize();
    final function = _contract.function(functionName);
    final encoded = function.encodeCall(params);
    return '0x${encoded.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  // Sends a transaction through MetaMask — user signs in MetaMask app.
  Future<String> _sendTransaction({
    required String fromAddress,
    required String data,
    String value = '0x0',
  }) async {
    final modal = WalletService().modal;

    if (modal == null) {
      throw Exception('Wallet not connected');
    }

    // Send transaction request to MetaMask via WalletConnect.
    final result = await modal.request(
      topic: modal.session!.topic,
      chainId: 'eip155:$_chainId',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': fromAddress,
            'to': _contractAddress,
            'data': data,
            'value': value,
          }
        ],
      ),
    );

    return result.toString();
  }

  // Book appointment — patient sends 0.01 ETH to the contract.
  Future<String> bookAppointment({
    required String patientAddress,
    required String doctorAddress,
  }) async {
    await _initialize();

    final data = await _encodeFunctionCall(
      'bookAppointment',
      [EthereumAddress.fromHex(doctorAddress)],
    );

    return _sendTransaction(
      fromAddress: patientAddress,
      data: data,
      // 0.01 ETH in hex Wei.
      value: _appointmentPriceHex,
    );
  }

  // Start meeting — doctor triggers payment release.
  Future<String> startMeeting({
    required String doctorAddress,
    required int appointmentId,
  }) async {
    await _initialize();

    final data = await _encodeFunctionCall(
      'startMeeting',
      [BigInt.from(appointmentId)],
    );

    return _sendTransaction(
      fromAddress: doctorAddress,
      data: data,
    );
  }

  // Cancel by patient — partial refund.
  Future<String> cancelByPatient({
    required String patientAddress,
    required int appointmentId,
  }) async {
    await _initialize();

    final data = await _encodeFunctionCall(
      'cancelByPatient',
      [BigInt.from(appointmentId)],
    );

    return _sendTransaction(
      fromAddress: patientAddress,
      data: data,
    );
  }

  // Cancel by doctor — full refund to patient.
  Future<String> cancelByDoctor({
    required String doctorAddress,
    required int appointmentId,
  }) async {
    await _initialize();

    final data = await _encodeFunctionCall(
      'cancelByDoctor',
      [BigInt.from(appointmentId)],
    );

    return _sendTransaction(
      fromAddress: doctorAddress,
      data: data,
    );
  }
}
