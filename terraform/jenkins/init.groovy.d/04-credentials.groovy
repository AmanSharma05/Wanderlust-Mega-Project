import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

println("Configuring Jenkins Credentials...")

def jenkins = Jenkins.get()
def store = SystemCredentialsProvider.getInstance().getStore()

def existingCredentials = CredentialsProvider.lookupCredentials(
    StandardUsernamePasswordCredentials.class,
    jenkins,
    null,
    null
)

def createCredential = { credentialId, description, username, password ->

    if (!username?.trim() || !password?.trim()) {
        println("Skipping '${credentialId}' - Username or Password not provided.")
        return
    }

    if (existingCredentials.find { it.id == credentialId }) {
        println("Credential '${credentialId}' already exists.")
        return
    }

    def credential = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialId,
        description,
        username,
        password
    )

    store.addCredentials(Domain.global(), credential)

    println("Credential '${credentialId}' created successfully.")
}

createCredential(
    "Github-cred",
    "GitHub Credentials",
    System.getenv("GITHUB_USERNAME"),
    System.getenv("GITHUB_TOKEN")
)

createCredential(
    "Dockerhub-Cred",
    "DockerHub Credentials",
    System.getenv("DOCKERHUB_USERNAME"),
    System.getenv("DOCKERHUB_PASSWORD")
)

jenkins.save()
println("Jenkins Credentials Configuration Complete")