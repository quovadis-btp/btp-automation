btp contexts
=============

BTP contexts are a way of defining logical entities to host amd implement various contexts, namely bootstrap, runtime, provider and consumer.  

The main idea behind the contexts is to break silos of global account, subaccounts across different regions and break free from 
the rigidity of the cloud foundry runtime org structure.

In a nutshell, contexts are declarative entities, defined as terraform scripts and orchestrated by CI/CD pipelines. 

PS.
Both cf and k8s runtimes can be used jointly or seperately in their respective runtime contexts



[cf architecture](https://docs.cloudfoundry.org/concepts/architecture/)  
![image](https://github.com/user-attachments/assets/83226447-29d4-4ae4-89d7-47354154dd9f)


[k8s architecture](https://phoenixnap.com/kb/understanding-kubernetes-architecture-diagrams)  
![image](https://github.com/user-attachments/assets/649532ff-d679-4ea9-884d-c3fbd6edc528)

