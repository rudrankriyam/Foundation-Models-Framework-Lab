//
//  InvoiceProcessingSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct InvoiceProcessingSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var invoiceText = """
    INVOICE #2025-001
    Date: January 15, 2025
    Due Date: February 14, 2025

    From:
    TechCorp Solutions Inc.
    123 Innovation Drive
    San Francisco, CA 94105
    Tax ID: 87-1234567

    Bill To:
    Acme Corporation
    456 Business Blvd
    New York, NY 10001

    Description                          Qty    Unit Price    Amount
    ----------------------------------------------------------------
    Software Development Services         80     $150.00    $12,000.00
    Cloud Infrastructure Setup            1     $2,500.00    $2,500.00
    Monthly Support Package               3       $800.00    $2,400.00
    Security Audit                        1     $3,200.00    $3,200.00

    Subtotal:                                              $20,100.00
    Tax (8.875%):                                           $1,783.88
    ----------------------------------------------------------------
    Total Due:                                             $21,883.88

    Payment Terms: Net 30
    Please include invoice number with payment.
    """

    @State private var extractionMode = 0
    @State private var includeLineItems = true
    @State private var calculateTotals = true

    private let modes = ["Full Invoice", "Summary Only", "Line Items Focus"]

    private var modeSelectorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Extraction Mode")
                .font(.headline)

            Picker("Mode", selection: $extractionMode) {
                ForEach(0..<modes.count, id: \.self) { index in
                    Text(modes[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Toggle("Extract line items", isOn: $includeLineItems)
                .disabled(extractionMode == 1) // Disabled for summary only

            Toggle("Validate calculations", isOn: $calculateTotals)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(.rect(cornerRadius: 8))
    }

    private var sampleInvoiceLoaderSection: some View {
        HStack {
            Spacer()
            Button("Load Sample Invoice") {
                loadSampleInvoice()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
    }

    var body: some View {
        ExampleViewBase(
            title: "Invoice Processing",
            description: "Extract structured data from real-world invoices using complex schemas",
            currentPrompt: $invoiceText,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { await runExample() },
            onReset: { executor.reset() },
            content: {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                modeSelectorSection
                optionsSection
                sampleInvoiceLoaderSection

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extracted Invoice Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
        }
    )
}

    private func loadSampleInvoice() {
        invoiceText = """
        INVOICE
        Invoice Number: INV-2025-0042
        Date: March 1, 2025

        Seller:
        Creative Agency LLC
        789 Design Street, Suite 200
        Los Angeles, CA 90028
        Email: billing@creativeagency.com
        Phone: (323) 555-0100

        Buyer:
        StartUp Inc.
        321 Venture Ave
        Austin, TX 78701
        Contact: Sarah Johnson

        Items:
        1. Logo Design and Branding Package
           Quantity: 1
           Rate: $5,000.00
           Amount: $5,000.00

        2. Website Design (10 pages)
           Quantity: 10
           Rate: $500.00 per page
           Amount: $5,000.00

        3. Social Media Templates
           Quantity: 20
           Rate: $75.00 each
           Amount: $1,500.00

        4. Brand Guidelines Document
           Quantity: 1
           Rate: $1,200.00
           Amount: $1,200.00

        Subtotal: $12,700.00
        Discount (10%): -$1,270.00
        Net Amount: $11,430.00
        Sales Tax (7.25%): $828.68

        Total Amount Due: $12,258.68

        Payment Due: March 31, 2025
        Late Fee: 1.5% per month after due date
        """
    }

    private func runExample() async {
        let schema: DynamicGenerationSchema

        switch extractionMode {
        case 0: // Full Invoice
            schema = InvoiceSchemas.createFullInvoiceSchema()
        case 1: // Summary Only
            schema = InvoiceSchemas.createSummarySchema()
        case 2: // Line Items Focus
            schema = InvoiceSchemas.createLineItemsSchema()
        default:
            return
        }

        await executor.execute(
            withPrompt: invoiceText,
            schema: schema,
            formatResults: { output in
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: formatted, encoding: .utf8) {

                    var result = jsonString

                    // Add validation results if enabled
                    if calculateTotals, let dict = json as? [String: Any] {
                        result += "\n\n=== Validation Results ==="
                        result += InvoiceSchemas.validateInvoiceTotals(dict)
                    }

                    return result
                }
                return output
            }
        )
    }
}

#Preview {
    NavigationStack {
        InvoiceProcessingSchemaView()
    }
}
