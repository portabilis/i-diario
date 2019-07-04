 require 'spec_helper'

describe EntitySingletoon do

  let!(:entity) { create(:entity, domain: :foo, config: { database: "entity" }) }
  let!(:entity_bar) { create(:entity, domain: :bar, config: { database: "bar" }) }
  let!(:entity_baz) { create(:entity, domain: :baz, config: { database: "baz" }) }

  describe "#current" do
    context "no entity setted" do
      it "should return nil" do
        expect(EntitySingletoon.current).to eql(nil)
      end
    end

    context "with entity setted" do
      around(:each) do |example|
        EntitySingletoon.set(entity)
        example.run
        EntitySingletoon.set nil
      end
      
      it "should return entity" do
        expect(EntitySingletoon.current).to eql(entity)
      end
    end

    describe "inside with block" do

      context "with no entity setted before" do
        it "should run in context of entity" do
          EntitySingletoon.with(entity) do
            expect(EntitySingletoon.current).to eql(entity)
          end
        end

        it "should set nil entity after execute" do
          EntitySingletoon.with(entity) {}
          expect(EntitySingletoon.current).to eql(nil)
        end
      end
  
      context "with entity setted before" do

        around(:each) do |example|
          EntitySingletoon.set entity_bar
          example.run
          EntitySingletoon.set nil
        end
        
        it "should run in context of entity" do
          EntitySingletoon.with(entity) do
            expect(EntitySingletoon.current).to eql(entity)
          end
        end
  
        it "should set previous entity" do
          EntitySingletoon.with(entity) {}
          expect(EntitySingletoon.current).to eql(entity_bar)
        end
      end
  
      context "threads" do
        it "should be threadsafe" do
          threads = []
  
          EntitySingletoon.with(entity_baz) do
  
            Thread.new {
              expect(EntitySingletoon.current).to eql(entity_baz)
              Thread.new {
                expect(EntitySingletoon.current).to eql(entity_baz)
  
                EntitySingletoon.with(entity) do
                  expect(EntitySingletoon.current).to eql(entity)
                end
  
                expect(EntitySingletoon.current).to eql(entity_baz)
              }.join
              expect(EntitySingletoon.current).to eql(entity_baz)
              
            }.join
  
            expect(EntitySingletoon.current).to eql(entity_baz)
  
            Thread.new {
              expect(EntitySingletoon.current).to eql(entity_baz)
            }.join
  
            threads << Thread.new {
              10.times do
                expect(EntitySingletoon.current).to eql(entity_baz)
                sleep 0.03
              end
            }
    
            threads << Thread.new {
              EntitySingletoon.with(entity) do
                10.times do
                  expect(EntitySingletoon.current).to eql(entity)
                  sleep 0.03
                end
              end
            }
    
            threads << Thread.new {
              EntitySingletoon.with(entity_bar) do
                10.times do
                  sleep 0.03
                  expect(EntitySingletoon.current).to eql(entity_bar)
                end
              end
            }
    
            expect(EntitySingletoon.current).to eql(entity_baz)
    
            threads.map &:join
    
            expect(EntitySingletoon.current).to eql(entity_baz)
          end
  
          expect(EntitySingletoon.current).to eql(nil)
        end
      end
    end
  end
  

  
  
end
