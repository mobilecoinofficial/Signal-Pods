//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation
import LibMobileCoin

final class ConsensusConnection:
    Connection<GrpcProtocolConnectionFactory.ConsensusServiceProvider, HttpProtocolConnectionFactory.ConsensusServiceProvider>, ConsensusService
{
    private let httpFactory: HttpProtocolConnectionFactory
    private let grpcFactory: GrpcProtocolConnectionFactory
    private let config: AttestedConnectionConfig<ConsensusUrl>
    private let targetQueue: DispatchQueue?
    private let rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)?
    private let rngContext: Any?

    init(
        httpFactory: HttpProtocolConnectionFactory,
        grpcFactory: GrpcProtocolConnectionFactory,
        config: AttestedConnectionConfig<ConsensusUrl>,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        self.httpFactory = httpFactory
        self.grpcFactory = grpcFactory
        self.config = config
        self.targetQueue = targetQueue
        self.rng = rng
        self.rngContext = rngContext

        super.init(
            connectionOptionWrapperFactory: { transportProtocolOption in
                switch transportProtocolOption {
                case .grpc:
                    return .grpc(
                        grpcService: grpcFactory.makeConsensusService(
                            config: config,
                            targetQueue: targetQueue,
                            rng: rng,
                            rngContext: rngContext))
                case .http:
                    return .http(httpService: httpFactory.makeConsensusService(
                            config: config,
                            targetQueue: targetQueue,
                            rng: rng,
                            rngContext: rngContext))
                }
            },
            transportProtocolOption: config.transportProtocolOption,
            targetQueue: targetQueue)
    }

    func proposeTx(
        _ tx: External_Tx,
        completion: @escaping (Result<ConsensusCommon_ProposeTxResponse, ConnectionError>) -> Void
    ) {
        switch connectionOptionWrapper {
        case .grpc(let grpcConnection):
            grpcConnection.proposeTx(tx, completion: completion)
        case .http(let httpConnection):
            httpConnection.proposeTx(tx, completion: completion)
        }
    }
}
