import Foundation

struct CreateInvoiceLine: Codable, Hashable {
    var vatId: Int
    var lineableType: String = "Actuarial" // default hodnota
    var name: String
    var quantity: Int
    var unitPrice: Double
    var basePrice: Double
    var tax: Double
    var totalPrice: Double
    var unitName: String?
    
    enum CodingKeys: String, CodingKey {
        case vatId = "vat_id"
        case lineableType = "lineable_type"
        case name
        case quantity
        case unitPrice = "unit_price"
        case basePrice = "base_price"
        case tax
        case totalPrice = "total_price"
        case unitName = "unit_name"
    }
}
