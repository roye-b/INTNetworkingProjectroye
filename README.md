# Networking and Security Project  [![][autotest_badge]][autotest_workflow]

## Project goals

This project practices some important concepts in networking and security for a DevOps engineer.

You'll set up a standard public-and-private network structure in AWS.
Additionally, you'll automate SSH connection and key rotation.
Finally, you'll create a simplified version of the TLS handshake process to explore how symmetric and asymmetric encryption work.

## Preliminaries

1. Fork this repo by clicking **Fork** in the top-right corner of the page. 
2. Clone your forked repository by:
   ```bash
   git clone https://github.com/<your-username>/<your-project-repo-name>
   ```
   Change `<your-username>` and `<your-project-repo-name>` according to your GitHub username and the name you gave to your fork. E.g. `git clone https://github.com/johndoe/NetworkingProject`.

Let's get started...

## Part I: Build a network in AWS cloud

1. Complete the [AWS Virtual Private Cloud (VPC)][aws_vpc_tutorial] tutorial to build the following network architecture in AWS:

   ![][networking_project_vpc1]

    **Note:** No need to create **NAT gateway** in any way you choose.   

2. Create one EC2 instance in your public subnet and another one in your private subnet.
3. Connect to your public instance from your local machine. 
4. Can you connect it from your local machine? no... it has no public IP event, and it is not accessible from the internet at all.
   Think how you can use the **public instance** to connect to the **private instance**.
   Once you’re in the private instance, try to access the internet and make sure you don’t have access.
5. Answer the below questions in `SOLUTION`:

   - From your public instance, use `route -n` and the information under `/etc/resolv.conf` to determine the IP addresses of your **local DNS server**, and the **default gateway**.
   - From your public instance, search in `/var/log/syslog` logs that indicate the communication of the instance with the DHCP server. 
   - Specifically, find and indication for the 4 phases of DHCP IP allocation (DORA). 
   - Use `traceroute` to determine how many hops does a packet cross from the public instance to the private instance? Explain.
   - Can you resolve DNS address of a public website from the private instance? Explain.

## Part II: SSH bastion host

SSH jump host (also known as SSH **bastion** host or SSH gateway) is a special type of server that allows users to access other servers in a private network through it. 
It acts as an intermediary host between the client and the target server. 
By using a jump host, users can securely connect to remote servers that are not directly accessible from the internet or from their local machine.
The jump host acts as a secure entry point to the private network, enforcing authentication and access controls, and reducing the attack surface of the servers behind it.

Implement a bash script in `bastion_connect.sh` that connects to the private instance using the public instance. 

Your script should expect an environment variable called `KEY_PATH`, which is a path to the `.pem` ssh key file.
If the variable doesn't exist, it prints an error message and exits with code `5`. 

Here is how your script will be tested: 

**Case 1** - Connect to the private instance from your local machine

```console
myuser@hostname:~$ export KEY_PATH=~/key.pem
myuser@hostname:~$ ./bastion_connect.sh <public-instance-ip> <private-instance-ip>
ubuntu@private-instance-ip:~$ 
```

**Case 2** - Connect to the public instance

```console
myuser@hostname:~$ export KEY_PATH=~/key.pem
myuser@hostname:~$ ./bastion_connect.sh <public-instance-ip>
ubuntu@public-instance-ip:~$ 
```

**Case 3** - Run a command in the private machine

```console
myuser@hostname:~$ export KEY_PATH=~/key.pem
myuser@hostname:~$ ./bastion_connect.sh <public-instance-ip> <private-instance-ip> ls
some-file-in-private-ec2.txt 
```

**Case 4** - Bad usage

```console
myuser@hostname:~$ ./bastion_connect.sh <ip>
KEY_PATH env var is expected
myuser@hostname:~$ echo $?
5
myuser@hostname:~$ export KEY_PATH=~/key.pem
myuser@hostname:~$ ./bastion_connect.sh
Please provide bastion IP address
myuser@hostname:~$ echo $?
5

```

## Part III: SSH keys rotation

**Key rotation** is a security practice that involves regularly replacing cryptographic keys used for encryption, authentication, or authorization to mitigate the risk of compromise.
It helps to ensure that compromised keys are not used to gain unauthorized access and that any data that has been encrypted with the old keys is no longer accessible.
Key rotation is typically used in many security-related systems such as SSH, SSL/TLS, and various forms of encryption, and is a key component of maintaining a secure environment.

In your public EC2 instance, create a bash script under `~/ssh_keys_rotation.sh` that automatically rotates the keys of the **private instance**.

The script would be invoked by:

```console
ubuntu@<public-ip-host>:~$ ./ssh_keys_rotation.sh <private-instance-ip>
```

At the end of the execution, connection to the private instance would be allowed using a new key-pair (generated as part of the running of `ssh_keys_rotation.sh`).

```console
ubuntu@<public-ip-host>:~$ ssh -i <path_to_new_key> ubuntu@<private-ip-host>
ubuntu@<private-ip-host>:~$
```

Note that you should not be able to connect using the old SSH key:

```console
ubuntu@<public-ip-host>:~$ ssh -i <path_to_old_key> ubuntu@<private-ip-host>
ubuntu@<private-ip-host>: Permission denied (publickey).
```

**Note**: Make sure the rotation process doesn't break the `bastion_connect.sh` script from the previous question. The script should work fluently after rotation. 

In any case that you break the private instance, feel free to delete your EC2 instance and create a new one instead.

When done, copy your script content into the `ssh_keys_rotation.sh` file in this repo.

## Part IV: TLS Handshake 

![][networking_alice_bob]

As you may know, the communication in HTTP protocol is insecure, and since Eve is listening on the channel between you (Alice) and the web server (Bob), you are required to create a secure channel.
This is what HTTPS does, using the TLS protocol. 
The process of establishing a secure TLS connection involves several steps, known as TLS Handshake.

The TLS protocol uses a combination of **asymmetric** and **symmetric** encryption. Here is a **simplified** TLS handshake process:

#### Step 1 - Client Hello (Client -> Server).

First, the client sends a **Client Hello** message to the server.
The message includes:

- The client's TLS version.
- A list of supported ciphers.

#### Step 2 - Server Hello (Server -> Client)

The server replies with a **Server Hello**.
A Server Hello includes the following information:

- **Server Version** - a confirmation for the version specified in the client hello.
- **Session ID** - used to identify the current communication session between the server and the client.
- **Server digital certificate** - the certificate contains some details about the server, as well as a public key with which the client can encrypt messages to the server. The certificate itself is signed by Certificate Authority (CA).


#### Step 3 - Server Certificate Verification

Alice needs to verify that she's taking with Bob, the real Bob.
Why should she suspect? Since Eve is controlling every message that Bob sends to Alice,
Eve can impersonate Bob, talk with Alice on his behalf, without Alice to knowing that. 

Here the CA comes into the picture. CA is an entity (e.g. Amazon Web Services, Microsoft etc...) trusted by both sides (client and server) that issues and signs digital certificates, so the ownership of a public key can be easily verified.

In this step the client verifies the server's digital certificate. Which means, Alice verifies Bob's certificate.

#### Step 4 - Client-Server master-key exchange


Now, after Bob's certificate was verified successfully, the client and the server should agree on a **symmetric key** (called **master key**) with which they will communicate during the session.
The client generates a 32-bytes random master-key, encrypts it using the server's certificate and sends the encrypted message in the channel.

In addition to the encrypted master-key, the client sends a sample message to verify that the symmetric key encryption works.

> [!NOTE]
> The real TLS protocol doesn't use the master key for direct communication. Instead, other different session keys are generated and used to communicate symmetrically. 
> Both the client and the server's generate the keys each in his own machine.  

#### Step 5 - Server verification message

The server decrypts the encrypted master-key. 

From now on, every message between both sides will be symmetrically encrypted by the master-key.
The server encrypts the sample message and sends it back to the client.

#### Step 6 - Client verification message

The client verifies that the sample message was encrypted successfully.



### Implement the TLS handshake

Use the `scp` command to copy the directory `tls_webserver` into your home directory of your public EC2. 
This Python code implements an HTTP web server that represents Bob's side.
You will communicate with this server (as Alice), and implement the handshake process detailed above, over an insecure HTTP channel. 

Before you run the server on your public EC2 instance, you should install some Python packages:

```shell
sudo apt update && sudo apt install python3-pip
pip install aiohttp==3.9.3
```

The server can be run by:

```bash
python3 app.py
```

Note that the server is listening on port `8080`, but by default, the only allowed inbound traffic to an EC2 instance is port 22 (why?).
[Take a look here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html#add-rule-authorize-access) to know how to open port `8080` on your public EC2 instance. 

After the server is running and inbound traffic on port 8080 is allowed, you can test the server by executing the below command from your local machine:

```console
myuser@hostname:~$ curl <public-ec2-instance-ip>:8080/status
Hi! I'm available, let's start the TLS handshake
```

Your goal is to perform the above 6 steps using a bash script, and establish a secure channel with the server.

Below are some helpful instructions you may utilize in each step. Eventually, your code should be written in `tlsHandshake.sh` and executed by:

```bash
bash tlsHandshake.sh <server-ip>
```

While `<server-ip>` is the server public IP address. 

Make your script robust and clean, use variables, in every step check if the commands have succeeded and print informational messages accordingly. 

Use `curl` to send the following **Client Hello** HTTP request to the server:

```json lines
POST /clienthello
{
   "version": "1.3",
   "ciphersSuites": [
      "TLS_AES_128_GCM_SHA256",
      "TLS_CHACHA20_POLY1305_SHA256"
   ], 
   "message": "Client Hello"
}
```

`POST` is the request method, `/clienthello` is the endpoint, and the json is the body.

**Server Hello** response will be in the form:

```json
{
   "version": "1.3",
   "cipherSuite": "TLS_AES_128_GCM_SHA256", 
   "sessionID": "......",
   "serverCert": "......"
}
```

The response is in JSON format.
You may want to keep the `sessionID` in a variable, and the server cert in a file, for later usage.
Use the `jq` command to parse and save specific keys from the JSON response.

Assuming the server certificate was stored in `cert.pem` file, you can verify the certificate by:
```shell
openssl verify -CAfile cert-ca-aws.pem cert.pem
```

While `cert-ca-aws.pem` is the CA certificate file (in our case of Amazon Web Services). 
You can safely download it from: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/networking_project/cert-ca-aws.pem (`wget`...).

Upon a valid certificate validation, the following output will be printed to stdout:
```text
cert.pem: OK
```

If the verification fails, `exit` the program with exit code `5`, and print an informational message:

```text
Server Certificate is invalid.
```

Given a valid cert, generate 32 random bytes base64 string (e.g. using `openssl rand`). This string will be used as the **master-key**, save it somewhere for later usage.

Got tired? refresh yourself with some [interesting reading](https://www.bleepingcomputer.com/news/security/russia-creates-its-own-tls-certificate-authority-to-bypass-sanctions/amp/).

The bellow command can help you to encrypt the generated master-key secret with the server certificate:
```shell
openssl smime -encrypt -aes-256-cbc -in <file-contains-the-generated-master-key> -outform DER <file-contains-the-server-certificate> | base64 -w 0
```

When you are ready to send the encrypted master-key to the server, `curl` again an HTTP POST request to the server endpoint `/keyexchange`, with the following body:
```
POST /keyexchange
{
    "sessionID": SESSION_ID,
    "masterKey": MASTER_KEY,
    "sampleMessage": "Hi server, please encrypt me and send to client!"
}
```

While  `SESSION_ID` is the session ID you've got from the server's hello response.
Also, `MASTER_KEY` is your **encrypted** master key.

The response for the above request would be in the form:
```json
{
  "sessionID": ".....",
  "encryptedSampleMessage": "....."
}
```

All you have to do now is to decrypt the sample message and verify that it equals to the original sample message.
This will indicate that the server uses the master-key successfully.

Please note that the `encryptedSampleMessage` is base64 encoded, before you decrypt it, decode it using the `base64 -d` command.
Also, here is the command **used by the server** to encrypt the sample message, so you'll know which algorithm to use in order to decrypt it:

```bash
echo $SAMPLE_MESSAGE | openssl enc -e -aes-256-cbc -pbkdf2 -k $MASTER_KEY
```

You should `exit` the program upon an invalid decryption with exit code `6`, and print an informational message:

```text
Server symmetric encryption using the exchanged master-key has failed.
```

If everything is ok, print:

```text
Client-Server TLS handshake has been completed successfully
```

Well Done! you've manually implemented a secure communication over HTTP! Thanks god we have TLS in real life :-)


## Submission

Time to submit your solution for testing.

1. Since the automated test script should connect to your public virtual machine to test your solution, you should allow it an access, you guess right, using SSH keys. To do so:
   
   - Generate a new SSH key locally by:
     ```bash
     ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f github_test_ssh_key -N ""
     ```
     
     The private and public key were generated in the current working dir under `github_test_ssh_key` and `github_test_ssh_key.pub` correspondingly.      

   - Store the private key in your GitHub repository as a Secret:
      - Go to your project repository on GitHub, navigate to **Settings** > **Secrets and variables** > **Actions**.
      - Click on **New repository secret**.
      - Set the name to `PUBLIC_INSTANCE_SSH_KEY` (it must be exactly that name as the automated test script expect this secret name).
      - Paste the content of the private SSH key (`github_test_ssh_key`).
         
        **Note**: the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` are part of the key.
      - Click **Add secret**.
   - Add the public key to your `~/.ssh/authorized_keys` file of your **public instance**. 
   
   That way the automated test would have an access to your public instance. 

1. In addition, the automated script needs to know you public instance and private instance IPs. Put them in `ec2_instances.json`. E.g.:

   ```json
   {
      "public_instance_ip": "16.171.230.179",
      "private_instance_ip": "10.0.1.15"
   }
   ```

1. Commit and push your changes. The **only** files that have to be committed are `SOLUTION`, `bastion_connect.sh`, `tlsHandshake.sh` and `ec2_instances.json`.
1. In [GitHub Actions][github_actions], watch the automated test execution workflow (enable Actions if needed). 
   If there are any failures, click on the failed job and **read the test logs carefully**. Fix your solution, commit and push again.

   **Note:** Your EC2 instances should be running while the automated test is performed. **Don't forget to turn off the machines when you're done**.

## Good Luck


[DevOpsTheHardWay]: https://github.com/exit-zero-academy/DevOpsTheHardWay
[onboarding_tutorial]: https://github.com/exit-zero-academy/DevOpsTheHardWay/blob/main/tutorials/onboarding.md
[BashProject]: https://github.com/exit-zero-academy/BashProject
[aws_vpc_tutorial]: https://github.com/alonitac/DevOpsMay24/blob/main/tutorials/aws_vpc.md
[autotest_badge]: ../../actions/workflows/project_auto_testing.yaml/badge.svg?event=push
[autotest_workflow]: ../../actions/workflows/project_auto_testing.yaml/
[fork_github]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#forking-a-repository
[clone_pycharm]: https://www.jetbrains.com/help/pycharm/set-up-a-git-repository.html#clone-repo
[github_actions]: ../../actions
[networking_project_stop]: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/img/networking_project_stop.gif
[networking_project_vpc1]: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/img/networking_project_vpc1.png
[networking_alice_bob]: https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/img/networking_alice_bob.png
[networking and security]: https://github.com/exit-zero-academy/DevOpsTheHardWay/blob/main/tutorials/networking_security.md
