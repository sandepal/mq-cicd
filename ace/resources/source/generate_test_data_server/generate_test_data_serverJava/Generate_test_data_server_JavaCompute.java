
import com.ibm.broker.javacompute.MbJavaComputeNode;
import com.ibm.broker.plugin.MbElement;
import com.ibm.broker.plugin.MbException;
import com.ibm.broker.plugin.MbJSON;
import com.ibm.broker.plugin.MbMessage;
import com.ibm.broker.plugin.MbMessageAssembly;
import com.ibm.broker.plugin.MbOutputTerminal;
import com.ibm.broker.plugin.MbUserException;
import com.github.javafaker.Faker;


public class Generate_test_data_server_JavaCompute extends MbJavaComputeNode {

	public void evaluate(MbMessageAssembly inAssembly) throws MbException {
		MbOutputTerminal out = getOutputTerminal("out");
		MbOutputTerminal alt = getOutputTerminal("alternate");

		MbMessage inMessage = inAssembly.getMessage();
		MbMessageAssembly outAssembly = null;
		try {
			// create new message as a copy of the input
			MbMessage outMessage = new MbMessage();
			outAssembly = new MbMessageAssembly(inAssembly, outMessage);
			// ----------------------------------------------------------
			// Add user code below
			copyMessageHeaders(inMessage,outMessage);
			Faker faker = new Faker();
		
	        // Parse input
	        MbElement inputRoot = inMessage.getRootElement();
	        MbElement request = inputRoot.getFirstElementByPath("JSON/Data/Request");
	        String type = request.getFirstElementByPath("type").getValueAsString();
	        
	        MbElement outRoot = outMessage.getRootElement();
	        MbElement outJson = outRoot.createElementAsLastChild(MbJSON.PARSER_NAME);
	        MbElement outData = outJson.createElementAsLastChild(MbElement.TYPE_NAME, "Data", null);
	        
	        boolean nameGenerated = false;
	        
	        if ("person".equalsIgnoreCase(type)) {
	            // Proceed if type is person	            

	            // Handle details (may be multiple 'detail' fields)
	            MbElement detailElem = request.getFirstElementByPath("detail");
	            if (detailElem != null) {
	                String detailString = detailElem.getValueAsString(); // e.g., "name;email;job"
	                String[] details = detailString.split(";");          // Split by ;
	                
	                for (String detail : details) {
	                    switch (detail.trim().toLowerCase()) {
	                        case "email":
	                            outData.createElementAsLastChild(MbElement.TYPE_NAME_VALUE, "email", faker.internet().emailAddress());
	                            break;
	                        case "job":
	                            outData.createElementAsLastChild(MbElement.TYPE_NAME_VALUE, "job", faker.job().title());
	                            break;
	                        case "phone":
	                            outData.createElementAsLastChild(MbElement.TYPE_NAME_VALUE, "phone", faker.phoneNumber().cellPhone());
	                            break;
	                        case "address":
	                            outData.createElementAsLastChild(MbElement.TYPE_NAME_VALUE, "address", faker.address().streetAddress());
	                            break;
	                        default:
	                            // Optionally ignore unknown fields
	                        	if (!nameGenerated) {
	                        		outData.createElementAsLastChild(MbElement.TYPE_NAME_VALUE, "name", faker.name().fullName());
	                                nameGenerated = true;
	                            }	                        	
	                            break;
	                    }
	                }
	            }
	        
	        }
			
			// End of user code
			// ----------------------------------------------------------
		} catch (MbException e) {
			// Re-throw to allow Broker handling of MbException
			throw e;
		} catch (RuntimeException e) {
			// Re-throw to allow Broker handling of RuntimeException
			throw e;
		} catch (Exception e) {
			// Consider replacing Exception with type(s) thrown by user code
			// Example handling ensures all exceptions are re-thrown to be handled in the flow
			throw new MbUserException(this, "evaluate()", "", "", e.toString(), null);
		}
		// The following should only be changed
		// if not propagating message to the 'out' terminal
		out.propagate(outAssembly);

	}
	
	
	public void copyMessageHeaders(MbMessage inMessage, MbMessage outMessage) throws MbException
	{
		MbElement outRoot = outMessage.getRootElement();
		MbElement header = inMessage.getRootElement().getFirstChild();

		while(header != null && header.getNextSibling() != null)
		{
			outRoot.addAsLastChild(header.copy());
			header = header.getNextSibling();
		}
	}
	

	/**
	 * onPreSetupValidation() is called during the construction of the node
	 * to allow the node configuration to be validated.  Updating the node
	 * configuration or connecting to external resources should be avoided.
	 *
	 * @throws MbException
	 */
	@Override
	public void onPreSetupValidation() throws MbException {
	}

	/**
	 * onSetup() is called during the start of the message flow allowing
	 * configuration to be read/cached, and endpoints to be registered.
	 *
	 * Calling getPolicy() within this method to retrieve a policy links this
	 * node to the policy. If the policy is subsequently redeployed the message
	 * flow will be torn down and reinitialized to it's state prior to the policy
	 * redeploy.
	 *
	 * @throws MbException
	 */
	@Override
	public void onSetup() throws MbException {
	}

	/**
	 * onStart() is called as the message flow is started. The thread pool for
	 * the message flow is running when this method is invoked.
	 *
	 * @throws MbException
	 */
	@Override
	public void onStart() throws MbException {
	}

	/**
	 * onStop() is called as the message flow is stopped. 
	 *
	 * The onStop method is called twice as a message flow is stopped. Initially
	 * with a 'wait' value of false and subsequently with a 'wait' value of true.
	 * Blocking operations should be avoided during the initial call. All thread
	 * pools and external connections should be stopped by the completion of the
	 * second call.
	 *
	 * @throws MbException
	 */
	@Override
	public void onStop(boolean wait) throws MbException {
	}

	/**
	 * onTearDown() is called to allow any cached data to be released and any
	 * endpoints to be deregistered.
	 *
	 * @throws MbException
	 */
	@Override
	public void onTearDown() throws MbException {
	}

}
