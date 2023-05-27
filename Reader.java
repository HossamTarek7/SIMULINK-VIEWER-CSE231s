
package test;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import javafx.stage.FileChooser;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;





public class Reader {

    public static void read_file(ArrayList<Block> blockss, File selectedFile2) {
        ArrayList<String> readLines = new ArrayList<String>();
        //,ArrayList<Line> Lines

        // Show the file chooser dialog and get the selected file
        File selectedFile = selectedFile2;

        // Read the contents of the selected file
        try ( BufferedReader br = new BufferedReader(new FileReader(selectedFile))) {
            String line;
            while ((line = br.readLine()) != null) {

                if (line.equals("__MWOPC_PART_BEGIN__ /simulink/systems/system_root.xml")) {
                    break;

                }
            }

            
            
            while (true) {
                line = br.readLine();
                readLines.add(line);
                if (line.equals("</System>")) {
                    break;

                }

            }
        } catch (IOException e) {
            System.err.format("IOException: %s%n", e);
        }

        try {
            // Create a DocumentBuilder
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();

            // Parse the XML text
            String lines = String.join("", readLines);
            InputSource inputSource = new InputSource(new StringReader(lines));
            Document doc = builder.parse(inputSource);
            Element blockElement = (Element) doc.getElementsByTagName("Block").item(0);

            // Get the list of Block elements
            NodeList portNodes = doc.getElementsByTagName("P");
            int numPorts = portNodes.getLength();

            // get the number of SIDs
            NodeList sidNodes = doc.getElementsByTagName("SID");

            String SID;
            String typename;
            String[] positions;
            NodeList blockList = doc.getElementsByTagName("Block");

            // Loop through each Block element and print its Name attribute
            for (int i = 0; i < blockList.getLength(); i++) {
                int[] array_postion = new int[4];
                blockElement = (Element) doc.getElementsByTagName("Block").item(i);
                Node blockNode = blockList.item(i);

                Element blockElement2 = (Element) blockNode;

                String blockName = blockNode.getAttributes().getNamedItem("Name").getNodeValue();
                typename = blockNode.getAttributes().getNamedItem("BlockType").getNodeValue();;
                SID = blockElement.getAttribute("SID");

                // extract Position information
                NodeList pNodes = blockElement.getElementsByTagName("P");
                Node positionNode = null;
                for (int j = 0; j < pNodes.getLength(); j++) {
                    Node pNode = pNodes.item(j);
                    if (pNode.getAttributes().getNamedItem("Name").getNodeValue().equals("Position")) {
                        positionNode = pNode;
                        break;
                    }
                }

                if (positionNode != null) {
                    String position = position = positionNode.getTextContent();
                    positions = position.replaceAll("\\[|\\]", "").split(", ");
                    String xPos = positions[0];
                    array_postion[0] = Integer.parseInt(xPos);
                    String yPos = positions[1];
                    array_postion[1] = Integer.parseInt(yPos);
                    String width = positions[2];
                    array_postion[2] = Integer.parseInt(width);
                    String height = positions[3];
                    array_postion[3] = Integer.parseInt(height);

                }

                blockss.add(new Block(blockName, typename, Integer.parseInt(SID), array_postion));
            }
            Block.setNumber_of_blocks(blockList.getLength());

            // Get the list of Line elements
            // Loop through each Line element and print its ZOrder attribute
            NodeList lineList = doc.getElementsByTagName("Line");
            System.out.println("Number of Lines: " + lineList.getLength());

            // Loop through each Line element and print its ZOrder attribute
            for (int i = 0; i < lineList.getLength(); i++) {
                String dst;
                Element lineElement = (Element) lineList.item(i);

                Node lineNode = lineList.item(i);

                String points = lineElement.getElementsByTagName("P").item(2).getTextContent();

                System.out.println("line points " + points);
                // extract Src information
                NodeList nodeList = lineNode.getChildNodes();
                Node srcNode = null;
                Node dstNode = null;
                for (int j = 0; j < nodeList.getLength(); j++) {
                    Node pNode = nodeList.item(j);
                    if (pNode.getNodeName().equals("P") && pNode.getAttributes().getNamedItem("Name").getNodeValue().equals("Src")) {
                        srcNode = pNode;
                        break;
                    }
                }
                NodeList branchList = lineElement.getElementsByTagName("Branch");

                Node branchnode = null;
                if (branchList.getLength() > 0) {

                    for (int j = 0; j < branchList.getLength(); j++) {
                        Element branchElement = (Element) branchList.item(j);
                        branchnode = branchList.item(j);

                        String pointsb = branchElement.getElementsByTagName("P").item(1).getTextContent();

                        System.out.println("branch points:  " + pointsb);

                    }
                }

                for (int j = 0; j < nodeList.getLength(); j++) {
                    Node pNode = nodeList.item(j);
                    if (pNode.getNodeName().equals("P") && pNode.getAttributes().getNamedItem("Name").getNodeValue().equals("Dst")) {
                        dstNode = pNode;
                        break;
                    }
                }

                if (srcNode != null) {
                    String src = srcNode.getTextContent();
                    System.out.println("line number  " + i + "  Line src: " + src);
                }

                if (dstNode != null) {
                    dst = dstNode.getTextContent();
                    System.out.println("line number  " + i + "  Line dst: " + dst);
                }

                if (branchnode != null) {

                    branchnode = branchList.item(1);

                    dst = branchnode.getTextContent();
                    System.out.println("line number  " + i + "  Line dst: " + dst);
                }

            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

}
