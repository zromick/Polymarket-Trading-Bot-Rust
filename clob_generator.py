import os
from dotenv import load_dotenv
from py_clob_client.client import ClobClient

load_dotenv()


def generate_credentials():
    private_key = os.getenv("POLYMARKET_PRIVATE_SIGNER_KEY")
    proxy_address = os.getenv("POLYMARKET_PROXY_ADDRESS")

    if not private_key or not proxy_address or "YOUR_PROXY" in proxy_address:
        print(
            "[INTERNAL ERROR] Check your .env file. Missing Private Key or Proxy Address."
        )
        return

    client = ClobClient(
        host="https://clob.polymarket.com",
        key=private_key,
        chain_id=137,
        funder=proxy_address,
        signature_type=1,
    )

    print(f"[SYSTEM] Target Proxy: {proxy_address}")

    try:
        server_time = client.get_server_time()
        print(f"[SYSTEM] Connection successful. Server Time: {server_time}")
    except Exception as e:
        print(
            f"[API ERROR] Handshake failed. This is likely a regional geoblock. Details: {e}"
        )
        return

    try:
        print(f"[SYSTEM] Requesting new API key from Polymarket...")
        creds = client.create_api_key()

        print("\n" + "=" * 40)
        print("   SUCCESS! COPY TO CONFIG.JSON")
        print("=" * 40)
        print(f"'api_key': '{creds.api_key}',")
        print(f"'api_secret': '{creds.api_secret}',")
        print(f"'api_passphrase': '{creds.api_passphrase}',")
        print(f"'proxy_wallet_address': '{proxy_address}',")
        print("=" * 40)

    except Exception as e:
        print(f"[API ERROR] Polymarket rejected the request: {e}")
        print("\n--- TROUBLESHOOTING ---")
        print("1. GAS: Does the Signer (Magic wallet) have ~0.1 POL?")
        print("2. FUNDS: Does the Proxy (0x9308...) have at least $1 USDC?")
        print("3. LOCATION: Are you running this from a restricted region?")


if __name__ == "__main__":
    generate_credentials()
