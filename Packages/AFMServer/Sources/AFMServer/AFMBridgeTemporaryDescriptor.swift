import Darwin

struct AFMBridgeTemporaryDescriptor {
    let name: String
    let fileDescriptor: CInt
    let status: stat
}
