import time
import argparse
from some_package.some_utils import print_message

'''
Dummy script that just prints a message to terminal every 3 seconds.
'''

def main(user, key, port):
    while True:
        print_message()
        print(f"Username: {user}, Key: {key}, Port: {port}")
        time.sleep(3)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some arguments.')
    parser.add_argument('--user', type=str, required=True, help='The username to be processed')
    parser.add_argument('--key', type=str, required=True, help='The key to be processed')
    parser.add_argument('--port', type=int, required=True, help='The port to be processed')

    args = parser.parse_args()

    main(args.name, args.key, args.port)
