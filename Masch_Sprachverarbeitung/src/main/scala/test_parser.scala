import scala.xml.XML

object test_parser extends App{
  val xml = XML.loadFile("books.xml")
  print("yayy it worked")

}
